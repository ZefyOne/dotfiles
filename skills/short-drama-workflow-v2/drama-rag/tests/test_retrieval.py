"""Exercise the public CLIs with invented sources and a private temporary index."""

import json
import sqlite3
import subprocess
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from xml.etree import ElementTree as ET
from zipfile import ZipFile


SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
TRADE = "摊主：最多给你三十。\n▲ 阿琴收起布包，往门口走。\n摊主：等一下！四十，给我留下。"


def write_word(path, text):
    w = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
    document = ET.Element(w + "document")
    body = ET.SubElement(document, w + "body")
    run = ET.SubElement(ET.SubElement(body, w + "p"), w + "r")
    for line in text.splitlines():
        ET.SubElement(run, w + "t").text = line
        ET.SubElement(run, w + "br")
    with ZipFile(path, "w") as archive:
        archive.writestr("word/document.xml", ET.tostring(document, encoding="utf-8"))


class RetrievalTests(unittest.TestCase):
    def setUp(self):
        tmp = TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.db = self.root / "index.sqlite3"
        self.sample = self.root / "assets/测试/样稿.docx"
        self.sample.parent.mkdir(parents=True)
        write_word(self.sample, "故事梗概\n买家压价，卖家要走，买家挽留。"
                   "\n第一集\n1-1\n摊主：等一下，我先把木牌拓下来。\n第二集\n2-1\n" + TRADE +
                   "\n2-2\n小华：木匣是我的。\n第二十一集\n21-1\n小华：银铃铛归你。")
        self.other = self.root / "assets/别的题材/另一稿.txt"
        self.other.parent.mkdir(parents=True)
        self.other.write_text("第2集\n2-1\n" + TRADE, encoding="utf-8")
        self.plan = self.root / "当前/规划.md"
        self.plan.parent.mkdir()
        self.plan.write_text("第二集\n这里只规划买家压价、要走和挽留。\n", encoding="utf-8")
        self.build("--project-dir", self.plan.parent)

    def cli(self, script, *args, check=True):
        result = subprocess.run([sys.executable, "-B", str(SCRIPTS / script), "--index",
                                 str(self.db), "--json", *map(str, args)],
                                capture_output=True, text=True, check=check)
        return json.loads(result.stdout)

    def build(self, *args, update=False, check=True):
        return self.cli("update_index.py" if update else "build_index.py",
                        "--root", self.root, *args, check=check)

    def find(self, query, *args):
        return self.cli("retrieve.py", "--query", query, *args)

    def test_style_matches_dialogue_with_different_words_and_keeps_scope(self):
        result = self.find("买家压价，卖家要走，买家挽留", "--mode", "style",
                           "--genre", "测试", "--episode-range", "第一集至第二集")
        self.assertEqual(result["count"], 1)
        scene = result["results"][0]
        self.assertEqual((scene["source"], scene["episode_start"], scene["scene"]),
                         ("assets/测试/样稿.docx", 2, "2-1"))
        self.assertIn(TRADE, scene["text"])
        self.assertNotIn("木匣", scene["text"])
        self.assertEqual(set(scene["matched_cues"]), {"压价", "要走", "挽留"})
        self.assertEqual(len(scene["version"]), 12)
        self.assertEqual(self.find("压价要走挽留", "--mode", "style", "--genre", "测试")
                         ["results"][0]["scene"], "2-1")
        self.assertEqual(self.find("压价要走挽留", "--mode", "style", "--genre", "测试",
                                   "--episode-range", "第一集")["count"], 0)

    def test_partial_style_hit_marks_the_missing_action(self):
        result = self.find("压价后改口认错", "--mode", "style", "--genre", "测试")
        self.assertEqual(result["count"], 1)
        self.assertEqual(result["results"][0]["matched_cues"], ["压价"])
        self.assertEqual(result["results"][0]["missing_cues"], ["改口认错"])
        wait = self.find("买家挽留", "--mode", "style", "--genre", "测试", "--episode-range", "第一集")
        self.assertEqual(wait["count"], 0)

    def test_scoped_project_facts_and_episode_filters(self):
        args = ("--source", self.sample, "--episode-range", "第二十一集")
        self.assertEqual(self.find("银铃铛", *args)["results"][0]["scene"], "21-1")
        self.assertEqual(self.find("银铃铛", "--episode-range", "1-20")["count"], 0)
        self.assertEqual(self.find("只规划", "--mode", "style")["count"], 0)
        self.assertEqual(self.find("只规划", "--source", "当前/规划.md")["count"], 1)

    def test_empty_matches_do_not_get_source_points(self):
        for mode in ("context", "style"):
            for q in ("ZXQNOHIT", "鲸群迁徙"):
                result = self.find(q, "--mode", mode)
                self.assertEqual(result["results"], [])
                self.assertTrue(result["reason"])

    def test_long_scene_carries_number_and_does_not_absorb_next_scene(self):
        long_text = "▲ 小华把盒子拿出来。\n" * 40
        write_word(self.sample, "第十二集\n12-1\n" + long_text + "小华：金扣在这儿。\n12-2\n小华：布鞋给你。")
        self.build("--source", self.sample, "--chunk-size", 80, "--chunk-overlap", 16, update=True)
        hit = self.find("金扣", "--mode", "style", "--episode-range", "12", "--source", self.sample)["results"][0]
        self.assertEqual(hit["scene"], "12-1")
        self.assertIn("金扣", hit["text"])
        self.assertNotIn("布鞋", hit["text"])
        self.assertLessEqual(len(hit["text"]), 80)

    def test_incremental_edits_and_scoped_removal(self):
        self.assertEqual(self.build("--source", self.sample, update=True)["skipped"], 1)
        old = self.find("木匣")["results"][0]["version"]
        write_word(self.sample, "第二集\n2-2\n小华：银茶壶归我。")
        self.assertEqual(self.build("--source", self.sample, update=True)["processed"], 1)
        self.assertEqual(self.find("木匣")["count"], 0)
        self.assertNotEqual(self.find("银茶壶")["results"][0]["version"], old)
        self.sample.unlink()
        self.assertEqual(self.build("--source", self.sample.parent, update=True)["removed"], 1)
        self.assertEqual(self.find("银茶壶")["count"], 0)
        self.assertEqual(self.find("布包", "--source", self.other)["count"], 1)

    def test_damaged_update_keeps_previous_version(self):
        self.sample.write_bytes(b"not a Word file")
        result = self.build("--source", self.sample, update=True, check=False)
        self.assertEqual(len(result["failed"]), 1)
        self.assertEqual(self.find("木匣")["count"], 1)
        rebuilt = self.build("--source", self.sample, "--rebuild", check=False)
        self.assertEqual(rebuilt["processed"], 0)
        self.assertEqual(self.find("木匣")["count"], 1)

    def test_old_hash_only_index_upgrades_without_changing_source(self):
        with sqlite3.connect(self.db) as db:
            db.execute("DROP TABLE rag_postings")
            db.execute("UPDATE documents SET metadata_json='{}'")
            db.execute("PRAGMA user_version=0")
        self.assertEqual(self.build("--source", self.sample, update=True)["processed"], 1)
        hit = self.find("木匣", "--episode-range", "二")["results"][0]
        self.assertEqual(hit["scene"], "2-2")


if __name__ == "__main__":
    unittest.main()
