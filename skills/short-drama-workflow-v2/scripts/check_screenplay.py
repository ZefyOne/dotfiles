#!/usr/bin/env python3
"""Check a delivered Word screenplay and compare it with approved drafts."""

import argparse
from collections import Counter
from dataclasses import dataclass, field
from difflib import SequenceMatcher
from pathlib import Path
import re
import sys
from xml.etree import ElementTree as ET
from zipfile import BadZipFile, ZipFile


CHINESE_DIGITS = "零一二三四五六七八九"
EPISODE_MARKER = re.compile(r"第\s*([0-9]+|[一二三四五六七八九十百]+)\s*集")
SCENE_MARKER = re.compile(r"[0-9]+\s*[-－–—]\s*[0-9]+")
TIME_LABELS = {"日/内", "日/外", "夜/内", "夜/外"}
EPISODE_GAP = 5
MAX_EPISODE = 100
MIN_EPISODE_CHARACTERS = 1000
MAX_EPISODE_CHARACTERS = 1060
MIN_FULL_SCRIPT_CHARACTERS = 80000
MAX_FULL_SCRIPT_CHARACTERS = 85000
SPEAKER_LABEL = re.compile(r"^[^：:\r\n]+[：:]\s*")


@dataclass
class Paragraph:
    text: str
    blank: bool


@dataclass
class Episode:
    number: int
    heading: str
    paragraphs: list = field(default_factory=list)

    def text_paragraphs(self):
        return [paragraph.text for paragraph in self.paragraphs if paragraph.text]


def chinese_number(number):
    if number < 10:
        return CHINESE_DIGITS[number]
    if number < 100:
        tens, units = divmod(number, 10)
        prefix = CHINESE_DIGITS[tens] if tens > 1 else ""
        suffix = CHINESE_DIGITS[units] if units else ""
        return f"{prefix}十{suffix}"
    return "一百"


CHINESE_EPISODES = {chinese_number(number): number for number in range(1, MAX_EPISODE + 1)}


def episode_number(text):
    match = EPISODE_MARKER.fullmatch(text)
    if match is None:
        return None
    number = match[1]
    if number.isascii():
        return int(number)
    return CHINESE_EPISODES.get(number)


def read_paragraph(element, word):
    parts = []
    contains_object_or_break = False
    for node in element.iter():
        if node.tag == word + "t":
            parts.append(node.text or "")
        elif node.tag == word + "tab":
            parts.append("\t")
        elif node.tag in {word + "br", word + "cr"}:
            contains_object_or_break = True
            if node.get(word + "type") not in {"page", "column"}:
                parts.append("\n")
        elif node.tag in {word + "drawing", word + "pict", word + "object", word + "sym"}:
            contains_object_or_break = True
    text = "".join(parts).strip()
    return Paragraph(text, not text and not contains_object_or_break)


def read_episodes(path, exclude_front_matter=False):
    if path.suffix.lower() != ".docx":
        raise ValueError(f"请提供 .docx 文件：{path}")
    try:
        with ZipFile(path) as document:
            root = ET.fromstring(document.read("word/document.xml"))
    except (OSError, BadZipFile, KeyError, ET.ParseError, RuntimeError) as error:
        raise ValueError(f"无法读取 Word 文件 {path}：{error}") from error

    word = root.tag.rpartition("}")[0] + "}"
    body = root.find(word + "body")
    if body is None:
        raise ValueError(f"Word 文件缺少正文结构：{path}")

    elements = list(body)
    if exclude_front_matter:
        for index, element in enumerate(elements):
            if element.tag == word + "p" and read_paragraph(element, word).text == "正文":
                elements = elements[index + 1:]
                break

    episodes = []
    for element in elements:
        if element.tag == word + "p":
            paragraph = read_paragraph(element, word)
            number = episode_number(paragraph.text)
            if number is not None:
                episodes.append(Episode(number, paragraph.text))
            elif episodes:
                episodes[-1].paragraphs.append(paragraph)
        elif episodes and element.tag != word + "sectPr":
            text = "\n".join(
                read_paragraph(item, word).text for item in element.iter(word + "p")
            ).strip()
            episodes[-1].paragraphs.append(Paragraph(text, False))
    return episodes


def parse_episode_range(value):
    match = re.fullmatch(r"([0-9]+)(?:-([0-9]+))?", value)
    if match:
        start = int(match[1])
        end = int(match[2] or match[1])
        if 1 <= start <= end <= MAX_EPISODE:
            return range(start, end + 1)
    raise argparse.ArgumentTypeError(f"集数用 1–{MAX_EPISODE} 内的整数或连续范围，例如 11 或 11-30")


def check_episode_order(episodes, expected):
    issues = []
    numbers = [episode.number for episode in episodes]
    counts = Counter(numbers)
    for label, values in (
        ("缺集", sorted(set(expected) - counts.keys())),
        ("超出指定范围", sorted(counts.keys() - set(expected))),
        ("重集", [number for number, count in sorted(counts.items()) if count > 1]),
    ):
        if values:
            issues.append(f"{label}：{', '.join(map(str, values))}")
    if numbers != sorted(numbers):
        issues.append(f"集数错序，实际顺序：{', '.join(map(str, numbers))}")
    return issues


def check_scenes(episode):
    issues = []
    line_positions = [(index, line.strip()) for index, paragraph in enumerate(episode.text_paragraphs())
                      for line in paragraph.splitlines() if line.strip()]
    lines = [line for _, line in line_positions]
    scenes = [index for index, line in enumerate(lines) if SCENE_MARKER.fullmatch(line)]
    if not scenes:
        return [f"第{episode.number}集：未找到场次编号"]
    if scenes[0]:
        issues.append(f"第{episode.number}集：首个场次编号前有正文或场头")

    for number, (start, end) in enumerate(zip(scenes, scenes[1:] + [len(lines)]), 1):
        label = lines[start]
        expected_label = f"{episode.number}-{number}"
        location = f"第{episode.number}集 · {label}"
        if label != expected_label:
            issues.append(f"{location}：场次编号应为 {expected_label}")
        header = lines[start + 1:end][:3]
        header_checks = (
            ("时间与内外景", bool(header) and header[0] in TIME_LABELS),
            ("场景栏", len(header) > 1 and header[1].startswith("场景：")
             and bool(header[1][3:].strip())),
            ("人物栏", len(header) > 2 and header[2].startswith("人物：")
             and bool(header[2][3:].strip())),
        )
        for name, valid in header_checks:
            if not valid:
                issues.append(f"{location}：{name}缺失或格式不符")
        body_start = start + 4
        if all(valid for _, valid in header_checks):
            heading_paragraphs = [index for index, _ in line_positions[start:body_start]]
            if len(set(heading_paragraphs)) != 4:
                issues.append(f"{location}：场次编号、时间与内外景、场景和人物应各自成段")
            if body_start == end:
                issues.append(f"{location}：场内正文为空")
            elif line_positions[body_start][0] == heading_paragraphs[-1]:
                issues.append(f"{location}：正文应在人物栏后另起一段")
        body_lines = lines[body_start:end]
        if any(line in TIME_LABELS or line.startswith(("场景：", "人物：")) for line in body_lines):
            issues.append(f"{location}：场内出现额外场头，请检查是否缺少场次编号")
    return issues


def check_format(episodes, expected):
    issues = check_episode_order(episodes, expected)
    for index, episode in enumerate(episodes):
        if not 1 <= episode.number <= MAX_EPISODE or episode.heading != (
            f"第{chinese_number(episode.number)}集"
        ):
            issues.append(f"第{episode.number}集：集标题应使用标准中文数字，实际为「{episode.heading}」")
        issues.extend(check_scenes(episode))
        if index == len(episodes) - 1:
            continue
        blank_count = 0
        for paragraph in reversed(episode.paragraphs):
            if not paragraph.blank:
                break
            blank_count += 1
        if blank_count != EPISODE_GAP:
            next_number = episodes[index + 1].number
            issues.append(
                f"第{episode.number}集→第{next_number}集：实际有 {blank_count} 个空段落，应为 {EPISODE_GAP} 个"
            )
    return issues


def count_episode_characters(episode):
    """Count screenplay body characters, including punctuation but not labels."""
    count = 0
    for paragraph in episode.text_paragraphs():
        if (SCENE_MARKER.fullmatch(paragraph) or paragraph in TIME_LABELS
                or paragraph.startswith(("场景：", "人物："))):
            continue
        if paragraph.startswith("▲"):
            body = paragraph[1:]
        else:
            body = SPEAKER_LABEL.sub("", paragraph, count=1)
        count += sum(not character.isspace() for character in body)
    return count


def check_lengths(episode_lengths, expected):
    issues = []
    for episode, length in episode_lengths:
        if not MIN_EPISODE_CHARACTERS <= length <= MAX_EPISODE_CHARACTERS:
            issues.append(
                f"第{episode.number}集：正文 {length} 字，应为 "
                f"{MIN_EPISODE_CHARACTERS}–{MAX_EPISODE_CHARACTERS} 字（含标点）"
            )
    if expected == range(1, 81):
        total = sum(length for _, length in episode_lengths)
        if not MIN_FULL_SCRIPT_CHARACTERS <= total <= MAX_FULL_SCRIPT_CHARACTERS:
            issues.append(
                f"第1–80集：正文合计 {total} 字，应为 "
                f"{MIN_FULL_SCRIPT_CHARACTERS}–{MAX_FULL_SCRIPT_CHARACTERS} 字（含标点）"
            )
    return issues


def compare_reference(path, references, draft_by_number, expected):
    compared = set()
    counts = Counter(episode.number for episode in references)
    issues = [f"定稿 {path.name} · 第{number}集：定稿集号重复，无法确定比对版本"
              for number in expected if counts[number] > 1]
    missing = [number for number in expected if number not in counts]
    if missing:
        issues.append(f"定稿 {path.name}：范围内缺集：{', '.join(map(str, missing))}")

    for approved in references:
        number = approved.number
        if number not in expected or counts[number] != 1:
            continue
        location = f"定稿 {path.name} · 第{number}集"
        draft = draft_by_number.get(number)
        if draft is None:
            issues.append(f"{location}：交稿中缺少该集或该集重复")
            continue

        approved_text = approved.text_paragraphs()
        draft_text = draft.text_paragraphs()
        if not approved_text:
            issues.append(f"{location}：定稿正文为空")
            continue
        matcher = SequenceMatcher(None, approved_text, draft_text, autojunk=False)
        for operation, old_start, old_end, new_start, new_end in matcher.get_opcodes():
            if operation == "equal":
                continue
            issues.append(f"{location}：正文与定稿不同（段号按非空段落计）")
            for paragraph_index in range(old_start, old_end):
                issues.append(f"  定稿第{paragraph_index + 1}段：{approved_text[paragraph_index]}")
            for paragraph_index in range(new_start, new_end):
                issues.append(f"  交稿第{paragraph_index + 1}段：{draft_text[paragraph_index]}")
        compared.add(number)
    return issues, compared


def main():
    parser = argparse.ArgumentParser(description="只读复核 Word 短剧稿的集场、集间空行、定稿版本和可选字数")
    parser.add_argument("draft", type=Path, help="待复查的 .docx")
    parser.add_argument("--episodes", required=True, type=parse_episode_range, help="应交集数，如 1-80")
    parser.add_argument("--reference", type=Path, action="append", default=[],
                        help="用于正文比对的定稿 .docx，可以指定多次")
    parser.add_argument("--reference-episodes", type=parse_episode_range, action="append", default=[],
                        help="对应定稿应比对的集数，按 --reference 的顺序逐份指定")
    parser.add_argument("--full-coverage", action="store_true",
                        help="要求定稿参照合计覆盖 --episodes 的全部集数")
    parser.add_argument("--check-length", action="store_true",
                        help="统计正文含标点的非空白字符，每集须为 1000–1060 字；"
                             "--episodes 1-80 时另查全剧 80000–85000 字。"
                             "用户另有篇幅或计数约定时可不启用此项")
    args = parser.parse_args()
    if len(args.reference) != len(args.reference_episodes):
        parser.error("每个 --reference 都须对应一个 --reference-episodes，按传入顺序配对")
    for expected in args.reference_episodes:
        if expected.start < args.episodes.start or expected.stop > args.episodes.stop:
            parser.error("定稿的比对范围必须在 --episodes 指定的交稿范围内")
    if args.full_coverage:
        covered = {number for episode_range in args.reference_episodes for number in episode_range}
        missing = sorted(set(args.episodes) - covered)
        if missing:
            parser.error(f"定稿参照未覆盖指定集数：{', '.join(map(str, missing))}")

    try:
        episodes = read_episodes(args.draft, exclude_front_matter=args.check_length)
        references = []
        for path, expected in zip(args.reference, args.reference_episodes):
            reference_episodes = read_episodes(path, exclude_front_matter=args.check_length)
            if args.draft.samefile(path):
                raise ValueError(f"定稿参照与待交稿指向同一个文件：{path}")
            references.append((path, reference_episodes, expected))
    except (OSError, ValueError) as error:
        print(error, file=sys.stderr)
        return 2

    issues = check_format(episodes, args.episodes)
    episode_lengths = []
    if args.check_length:
        episode_lengths = [(episode, count_episode_characters(episode)) for episode in episodes]
        issues.extend(check_lengths(episode_lengths, args.episodes))
    counts = Counter(episode.number for episode in episodes)
    draft_by_number = {episode.number: episode for episode in episodes
                       if counts[episode.number] == 1}
    comparison_scopes = []
    for path, reference_episodes, expected in references:
        differences, covered = compare_reference(path, reference_episodes, draft_by_number, expected)
        issues.extend(differences)
        comparison_scopes.append((path.name, expected, sorted(covered)))

    print(f"{args.draft.name}｜检查第{args.episodes.start}–{args.episodes.stop - 1}集")
    if args.check_length:
        for episode, length in episode_lengths:
            print(f"第{episode.number}集正文：{length} 字")
        total = sum(length for _, length in episode_lengths)
        print(f"本批正文合计：{total} 字（含标点，不含场头、说话人标签、▲和空白）")
    for name, expected, covered in comparison_scopes:
        coverage = ", ".join(map(str, covered)) or "无"
        print(f"定稿 {name}｜指定比对第{expected.start}–{expected.stop - 1}集｜参与比对的集数：{coverage}")
    if issues:
        for issue in issues:
            print(f"  {issue}")
        return 1
    print("复查通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
