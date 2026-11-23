#!/usr/bin/env python3
"""Build and search a local, source-attributed index of short-drama passages."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
import sqlite3
import sys
import zipfile
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterator, Sequence

from passages import chunk_text, parse_episode_filter, read_text


DEFAULT_CONFIG_PATH = Path(__file__).resolve().parent.parent / "config.json"
INDEX_VERSION = 2
ASCII_TOKEN = re.compile(r"[a-z][a-z0-9_]*|\d+(?:\.\d+)?")
HAN = re.compile(r"[\u3400-\u9fff]+")
QUERY_FILLER = set("主角 样稿 台词 对白 剧本 一段 帮我 帮忙 我要 我想 场景 的是 这个 一个 怎么 如何".split())

# Keep existing document and chunk tables. An incremental update also upgrades
# old chunks in the selected source set from a hash-only index.
SCHEMA = """
CREATE TABLE IF NOT EXISTS documents (
    id INTEGER PRIMARY KEY, path TEXT NOT NULL UNIQUE, display_path TEXT NOT NULL,
    sha256 TEXT NOT NULL, source_type TEXT NOT NULL, genre TEXT NOT NULL DEFAULT '',
    stage TEXT NOT NULL DEFAULT '', priority REAL NOT NULL DEFAULT 0,
    metadata_json TEXT NOT NULL DEFAULT '{}', updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS chunks (
    id INTEGER PRIMARY KEY,
    document_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL, text TEXT NOT NULL, episode_start INTEGER,
    episode_end INTEGER, scene TEXT NOT NULL DEFAULT '', terms_json TEXT NOT NULL,
    char_count INTEGER NOT NULL, UNIQUE(document_id, chunk_index)
);
CREATE INDEX IF NOT EXISTS idx_chunks_episode ON chunks(episode_start, episode_end);
CREATE TABLE IF NOT EXISTS rag_postings (
    term TEXT NOT NULL, chunk_id INTEGER NOT NULL REFERENCES chunks(id) ON DELETE CASCADE,
    PRIMARY KEY(term, chunk_id)
) WITHOUT ROWID;
CREATE INDEX IF NOT EXISTS idx_rag_postings_chunk ON rag_postings(chunk_id);
"""


def load_config(path: Path | None = None) -> dict:
    with (path or DEFAULT_CONFIG_PATH).open(encoding="utf-8") as handle:
        return json.load(handle)


def normalized(text: str) -> str:
    return "".join(text.lower().split())


def tokenize(text: str, *, query: bool = False) -> Counter:
    terms = Counter(ASCII_TOKEN.findall(text.lower()))
    for run in HAN.findall(text):
        if not query or len(run) == 1:
            terms.update(run)
        terms.update(run[i:i + 2] for i in range(len(run) - 1))
    if query:
        for term in QUERY_FILLER:
            terms.pop(term, None)
        for term in "的了在和是他她着把个有与就也我这请找要":
            terms.pop(term, None)
    return terms


def style_tags(text: str, config: dict) -> list[str]:
    flat = normalized(text)
    cues = config["style_cues"]
    found = {tag for tag, phrases in cues.items()
             if any(phrase in flat for phrase in (tag, *phrases))}
    # A line like "等一下" also occurs during weighing or payment. It only
    # suggests calling somebody back when there is a nearby departure cue.
    for tag, rule in config["style_context_cues"].items():
        anchor = rule["near_cue"]
        if tag in found or anchor not in found:
            continue
        radius = rule["window_chars"]
        for match in re.finditer("|".join(map(re.escape, rule["phrases"])), flat):
            nearby = flat[max(0, match.start() - radius):match.end() + radius]
            if any(phrase in nearby for phrase in (anchor, *cues[anchor])):
                found.add(tag)
                break
    return [tag for tag in cues if tag in found]


def infer_metadata(path: Path, root: Path, priority_map: dict) -> dict:
    # Use the workflow-relative path when available so an ancestor's name
    # cannot silently label every document in this workflow.
    relative = path.relative_to(root) if path.is_relative_to(root) else None
    parts = relative.parts[:-1] if relative else path.parent.parts
    name = path.stem.lower()
    genre, stage = "", ""
    if "assets" in parts:
        index = parts.index("assets") + 1
        genre = parts[index] if index < len(parts) else ""
        source_type = "sample"
    elif "references" in parts:
        source_type = "rules"
    elif "state" in name or "状态" in name:
        source_type = "project_state"
    elif "plan" in name or "规划" in name:
        source_type = "plan"
    elif "review" in name or "审" in name:
        source_type = "review"
    elif "screenplay" in name or "正文" in name:
        source_type = "screenplay"
    else:
        source_type = "document"
    for part in parts:
        if part in ("drama-planning", "drama-writing", "drama-review", "drama-controller"):
            stage = part.removeprefix("drama-")
            break
    return {"display_path": str(relative or path), "source_type": source_type,
            "genre": genre, "stage": stage,
            "priority": float(priority_map.get(source_type, priority_map.get("document", 0)))}


def source_paths(root: Path, sources: Sequence[str], projects: Sequence[str], config: dict) -> list[Path]:
    if not root.is_dir():
        raise ValueError(f"资料根目录不存在：{root}")
    paths = set()
    if not sources:
        for pattern in config["default_sources"]:
            if not any(c in pattern for c in "*?["):
                paths.add((root / pattern).resolve())
            else:
                paths.update(p.resolve() for p in root.glob(pattern) if p.is_dir())
    for name in (*sources, *projects):
        path = (root / Path(name).expanduser()).resolve()
        if not path.exists():
            raise ValueError(f"指定的资料路径不存在：{path}")
        paths.add(path)
    return sorted(paths)


def source_files(scope: Path, extensions: set[str]) -> Iterator[Path]:
    if scope.is_file():
        if scope.suffix.lower() not in extensions:
            raise ValueError(f"不支持的资料格式：{scope.name}")
        yield scope
    elif scope.is_dir():
        def on_error(error):
            raise error
        for directory, subdirs, files in os.walk(scope, onerror=on_error):
            subdirs[:] = sorted(d for d in subdirs if not d.startswith("."))
            for name in sorted(files):
                path = Path(directory) / name
                if not name.startswith((".", "~$")) and path.suffix.lower() in extensions and not path.is_symlink():
                    yield path


def index_file(db, path: Path, root: Path, config: dict, signature: str, size: int, overlap: int) -> bool:
    source = path.read_bytes()
    digest = hashlib.sha256(source).hexdigest()
    metadata = infer_metadata(path, root, config["source_priority"])
    metadata.update(version=digest[:12], index_signature=signature)
    encoded = json.dumps(metadata, ensure_ascii=False, sort_keys=True)
    old = db.execute("SELECT id, sha256, metadata_json FROM documents WHERE path=?", (str(path),)).fetchone()
    if old and old["sha256"] == digest and old["metadata_json"] == encoded:
        return False
    content = read_text(path, source)
    if old:
        db.execute("DELETE FROM documents WHERE id=?", (old["id"],))
    doc = db.execute(
        """INSERT INTO documents(path, display_path, sha256, source_type, genre, stage, priority,
                                 metadata_json, updated_at) VALUES (?,?,?,?,?,?,?,?,?)""",
        (str(path), metadata["display_path"], digest, metadata["source_type"], metadata["genre"],
         metadata["stage"], metadata["priority"], encoded, datetime.now(timezone.utc).isoformat())
    ).lastrowid
    is_script = metadata["source_type"] in ("sample", "screenplay") or (
        metadata["source_type"] == "document" and path.suffix.lower() == ".docx")
    for i, (text, start, end, scene) in enumerate(chunk_text(content, size, overlap, script=is_script)):
        terms = tokenize(text)
        terms.update("@" + tag for tag in style_tags(text, config))
        chunk = db.execute(
            """INSERT INTO chunks(document_id,chunk_index,text,episode_start,episode_end,scene,
                                  terms_json,char_count) VALUES (?,?,?,?,?,?,?,?)""",
            (doc, i, text, start, end, scene, json.dumps(terms, ensure_ascii=False), len(text))
        ).lastrowid
        db.executemany("INSERT INTO rag_postings(term,chunk_id) VALUES (?,?)",
                       ((term, chunk) for term in terms))
    return True


def rebuild_index(root: Path, index_path: Path, sources: Sequence[str], project_dirs: Sequence[str],
                  chunk_size: int, overlap: int, rebuild: bool, config: dict) -> dict:
    scopes = source_paths(root, sources, project_dirs, config)
    extensions = set(config["supported_extensions"])
    files = {path for scope in scopes for path in source_files(scope, extensions)}
    signature_data = [INDEX_VERSION, chunk_size, overlap, config["style_cues"], config["style_context_cues"]]
    signature = hashlib.sha256(json.dumps(signature_data, sort_keys=True).encode()).hexdigest()[:16]
    index_path.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(index_path, timeout=30)
    db.row_factory = sqlite3.Row
    failed, processed, skipped, removed = [], 0, 0, 0
    try:
        if db.execute("PRAGMA user_version").fetchone()[0] > INDEX_VERSION:
            raise ValueError("索引来自更新的 RAG 版本，请使用对应版本打开。")
        db.execute("PRAGMA foreign_keys=ON")
        db.executescript(SCHEMA)
        with db:
            db.execute("BEGIN IMMEDIATE")
            if rebuild:
                db.execute("DELETE FROM documents")
            else:
                for doc in db.execute("SELECT id,path FROM documents").fetchall():
                    path = Path(doc["path"])
                    if path not in files and any(path.is_relative_to(scope) for scope in scopes):
                        db.execute("DELETE FROM documents WHERE id=?", (doc["id"],))
                        removed += 1
            for path in sorted(files):
                db.execute("SAVEPOINT one_source")
                try:
                    changed = index_file(db, path, root, config, signature, chunk_size, overlap)
                    processed += int(changed)
                    skipped += int(not changed)
                except (OSError, ValueError, KeyError, sqlite3.Error, SyntaxError, EOFError,
                        RuntimeError, zipfile.BadZipFile) as error:
                    db.execute("ROLLBACK TO one_source")
                    failed.append({"path": str(path), "error": str(error)})
                finally:
                    db.execute("RELEASE one_source")
            if failed and rebuild:
                db.rollback()
                processed, removed = 0, 0
            else:
                db.execute(f"PRAGMA user_version={INDEX_VERSION}")
        documents = db.execute("SELECT COUNT(*) FROM documents").fetchone()[0]
        chunks = db.execute("SELECT COUNT(*) FROM chunks").fetchone()[0]
    finally:
        db.close()
    return {"index": str(index_path), "documents": documents, "chunks": chunks,
            "processed": processed, "skipped": skipped, "removed": removed, "failed": failed}


def build_index_cli(argv: Sequence[str] | None = None) -> int:
    config = load_config()
    parser = argparse.ArgumentParser(description="建立或增量更新短剧资料索引")
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--index", type=Path, required=True)
    parser.add_argument("--source", action="append", default=[], help="限定读取的资料文件或目录，可重复")
    parser.add_argument("--project-dir", action="append", default=[], help="同时加入指定的项目资料，可重复")
    parser.add_argument("--chunk-size", type=int, default=config["chunk_size"])
    parser.add_argument("--chunk-overlap", type=int, default=config["chunk_overlap"])
    parser.add_argument("--rebuild", action="store_true", help="用本次来源完整替换索引")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    if args.chunk_size <= 0 or not 0 <= args.chunk_overlap < args.chunk_size:
        parser.error("需要 0 ≤ chunk-overlap < chunk-size")
    try:
        result = rebuild_index(args.root.expanduser().resolve(), args.index.expanduser().resolve(),
                               args.source, args.project_dir, args.chunk_size, args.chunk_overlap,
                               args.rebuild, config)
    except (OSError, ValueError, sqlite3.Error) as error:
        parser.exit(1, f"{error}\n")
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"已更新 {result['processed']} 个文件，跳过 {result['skipped']} 个，"
              f"移除 {result['removed']} 个旧来源。共 {result['documents']} 个文档、{result['chunks']} 个片段。")
        if result["failed"]:
            print(json.dumps(result["failed"], ensure_ascii=False, indent=2), file=sys.stderr)
    return int(bool(result["failed"]))


def ranked_passages(db, query: str, top_k: int, genre, stage, source_type, episode_filter,
                    mode: str, sources: Sequence[str], config: dict) -> list[dict]:
    words = tokenize(query, query=True)
    tags = style_tags(query, config) if mode == "style" else []
    labels = {"@" + tag for tag in tags}
    wanted = set(words) | labels
    if not wanted or not top_k:
        return []

    # One temporary relation avoids SQLite's bound-parameter limit for long
    # queries and keeps both frequency lookup and candidate selection indexed.
    db.execute("CREATE TEMP TABLE query_terms(term TEXT PRIMARY KEY) WITHOUT ROWID")
    db.executemany("INSERT INTO query_terms VALUES (?)", ((term,) for term in wanted))
    count, avg_length = db.execute("SELECT COUNT(*),AVG(char_count) FROM chunks").fetchone()
    frequencies = dict(db.execute(
        """SELECT p.term,COUNT(*) FROM query_terms q CROSS JOIN rag_postings p
           ON p.term=q.term GROUP BY p.term"""))
    if not frequencies:
        return []
    weights = {term: math.log1p((count - df + 0.5) / (df + 0.5)) for term, df in frequencies.items()}
    filters, values = [], []
    if mode == "style" and not sources:
        filters.append("d.source_type='sample'")
    if mode == "style":
        # An 80-episode file often opens with a synopsis that literally names
        # the desired beats. Return drama from the episodes in that case, but
        # keep an unnumbered standalone dialogue sample usable.
        filters.append("""(c.scene!='' OR c.episode_start=c.episode_end OR NOT EXISTS (
            SELECT 1 FROM chunks body WHERE body.document_id=c.document_id
            AND (body.scene!='' OR body.episode_start=body.episode_end)))""")
    if sources:
        db.execute("CREATE TEMP TABLE query_sources(path TEXT PRIMARY KEY) WITHOUT ROWID")
        db.executemany("INSERT OR IGNORE INTO query_sources VALUES (?)", ((s,) for s in sources))
        filters.append("(d.display_path IN query_sources OR d.path IN query_sources)")
    if genre:
        # General rules and project facts may be unlabelled. Shared style
        # samples, on the other hand, must belong to the requested genre.
        filters.append("(d.genre=? OR (d.genre='' AND d.source_type!='sample'))")
        values.append(genre)
    if stage:
        filters.append("(d.stage=? OR d.stage='')")
        values.append(stage)
    if source_type:
        filters.append("d.source_type=?")
        values.append(source_type)
    if episode_filter:
        filters.append("c.episode_start<=? AND c.episode_end>=?")
        values.extend((episode_filter[1], episode_filter[0]))
    extra = "".join(" AND " + f for f in filters)
    sql = """SELECT c.*, d.display_path, d.source_type, d.genre, d.stage, d.priority,
                    d.sha256, d.metadata_json FROM chunks c JOIN documents d ON d.id=c.document_id
             WHERE c.id IN (SELECT p.chunk_id FROM query_terms q CROSS JOIN rag_postings p ON p.term=q.term)"""
    flat_query = normalized(query)
    results = []
    for row in db.execute(sql + extra, values):
        terms = json.loads(row["terms_json"])
        matched = [tag for tag in tags if "@" + tag in terms]
        if tags and not matched:
            continue
        # BM25 discounts incidental words in a long scene. Source preference
        # can break a close match, but cannot introduce an unmatched passage.
        norm = 1.2 * (0.25 + 0.75 * row["char_count"] / avg_length)
        score = 0.0
        for term in wanted.intersection(terms):
            freq = terms[term]
            score += weights[term] * freq * 2.2 / (freq + norm)
        if len(flat_query) >= 2 and flat_query in normalized(row["text"]):
            score += 1.0
        score += min(row["priority"] / 1000.0, 0.1)
        results.append({
            "id": row["id"], "score": round(score, 6), "text": row["text"],
            "source": row["display_path"], "source_type": row["source_type"],
            "genre": row["genre"], "stage": row["stage"], "version": row["sha256"][:12],
            "episode_start": row["episode_start"], "episode_end": row["episode_end"],
            "scene": row["scene"], "matched_cues": matched,
            "missing_cues": [tag for tag in tags if tag not in matched],
            "metadata": json.loads(row["metadata_json"]),
        })
    results.sort(key=lambda r: (-len(r["matched_cues"]), -r["score"], r["source"], r["id"]))
    if mode != "style" or not results:
        return results[:top_k]
    chosen, seen_scenes, seen_text = [], set(), set()
    best_coverage = len(results[0]["matched_cues"])
    for result in results:
        if len(result["matched_cues"]) < best_coverage:
            break
        location = (result["source"], result["episode_start"], result["episode_end"], result["scene"])
        located = result["episode_start"] is not None or bool(result["scene"])
        if (located and location in seen_scenes) or result["text"] in seen_text:
            continue
        chosen.append(result)
        seen_scenes.add(location)
        seen_text.add(result["text"])
        if len(chosen) == top_k:
            break
    return chosen


def retrieve(index_path: Path, query: str, top_k: int, genre: str | None, stage: str | None,
             source_type: str | None, episode_filter: tuple[int, int] | None, *,
             mode: str = "context", sources: Sequence[str] = (), config: dict | None = None) -> list[dict]:
    if not index_path.is_file():
        raise ValueError("索引不存在，请先用 build_index.py 建立本次资料的索引。")
    db = sqlite3.connect(index_path.resolve().as_uri() + "?mode=ro", uri=True, timeout=30)
    db.row_factory = sqlite3.Row
    try:
        db.execute("BEGIN")
        if db.execute("PRAGMA user_version").fetchone()[0] != INDEX_VERSION:
            raise ValueError("索引版本不匹配，请对原资料范围运行 update_index.py 后再检索。")
        return ranked_passages(db, query, top_k, genre, stage, source_type, episode_filter,
                               mode, sources, config or load_config())
    finally:
        db.close()


def format_context(query: str, results: Sequence[dict], max_chars: int, reason: str = "") -> str:
    lines = ["[RAG_CONTEXT]", f"查询：{query}", f"结果数：{len(results)}"]
    if reason:
        lines.append(f"原因：{reason}")
    for position, result in enumerate(results, 1):
        start, end = result["episode_start"], result["episode_end"]
        episode = "未标注" if start is None else (str(start) if start == end else f"{start}-{end}")
        lines.extend(["", f"[{position}] 来源：{result['source']}", f"类型：{result['source_type']}",
                      f"题材：{result['genre'] or '未标注'}", f"阶段：{result['stage'] or '未标注'}",
                      f"集数：{episode}", f"场次：{result['scene'] or '未标注'}",
                      f"版本：{result['version']}", f"分值：{result['score']}"])
        if result["matched_cues"]:
            lines.append("匹配的动作：" + "、".join(result["matched_cues"]))
        if result["missing_cues"]:
            lines.append("片段中未匹配的动作：" + "、".join(result["missing_cues"]))
        piece = result["text"]
        lines.extend(["原文：", piece if len(piece) <= max_chars else piece[:max_chars].rstrip() + "……"])
    lines.extend(["", "[RAG_SOURCES]"])
    lines.extend("- " + source for source in dict.fromkeys(r["source"] for r in results))
    lines.append("[RAG_CONTEXT_END]")
    return "\n".join(lines)


def retrieve_cli(argv: Sequence[str] | None = None) -> int:
    config = load_config()
    parser = argparse.ArgumentParser(description="查找带出处的剧本原文和写作样稿")
    parser.add_argument("--index", type=Path, required=True)
    parser.add_argument("--query", required=True)
    parser.add_argument("--mode", choices=("context", "style"), default="context")
    parser.add_argument("--top-k", type=int)
    parser.add_argument("--max-chars-per-result", type=int, default=config["max_chars_per_result"])
    parser.add_argument("--genre")
    parser.add_argument("--stage")
    parser.add_argument("--source-type")
    parser.add_argument("--source", action="append", default=[], help="只从此原文件取材，可重复。使用索引中的相对路径或绝对路径")
    parser.add_argument("--episode-range")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    top_k = args.top_k if args.top_k is not None else config["style_top_k" if args.mode == "style" else "top_k"]
    if top_k < 0 or args.max_chars_per_result <= 0:
        parser.error("top-k 必须大于等于 0，max-chars-per-result 必须大于 0")
    try:
        episodes = parse_episode_filter(args.episode_range)
        results = retrieve(args.index.expanduser(), args.query, top_k, args.genre, args.stage,
                           args.source_type, episodes, mode=args.mode,
                           sources=[str(Path(s).expanduser()) for s in args.source], config=config)
    except (OSError, ValueError, sqlite3.Error) as error:
        parser.exit(1, f"{error}\n")
    reason = ""
    if not results:
        reason = "本次条件下没有匹配原文。" if top_k else "请求返回零条结果。"
    if args.json:
        print(json.dumps({"query": args.query, "mode": args.mode, "count": len(results),
                          "reason": reason, "results": results}, ensure_ascii=False, indent=2))
    else:
        print(format_context(args.query, results, args.max_chars_per_result, reason))
    return 0


def update_index_cli(argv: Sequence[str] | None = None) -> int:
    return build_index_cli(argv)
