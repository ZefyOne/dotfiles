"""Read source paragraphs and keep each passage inside its episode and scene."""

from __future__ import annotations

import re
import zipfile
from io import BytesIO
from pathlib import Path
from typing import Iterator
from xml.etree import ElementTree


DIGITS = "零一二三四五六七八九"
NUMBER = r"[\d零〇一二两三四五六七八九十百千]+"
DASH = r"[-—–－~～至到]"
EPISODE = re.compile(rf"第\s*({NUMBER})\s*(?:集\s*)?(?:{DASH}\s*第?\s*({NUMBER})\s*)?集")
HEADING = re.compile(rf"^\s*(?:#{{1,6}}\s*)?[*【《\[]*\s*{EPISODE.pattern}")
SCENE = re.compile(r"^\s*(?:#{1,6}\s*)?(?:场次\s*[:：]?\s*)?(\d{1,3})\s*[-—－.]\s*(\d{1,3})(?=$|[\s、:：.（(日夜])")
W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"


def number(value: str) -> int:
    value = value.replace("两", "二").replace("〇", "零")
    if value.isdecimal():
        return int(value)
    if all(ch in DIGITS for ch in value):
        return int("".join(str(DIGITS.index(ch)) for ch in value))
    units = {"十": 10, "百": 100, "千": 1000}
    total, digit = 0, None
    for ch in value:
        if ch in units:
            total += (digit if digit is not None else 1) * units[ch]
            digit = None
        else:
            digit = int(ch) if ch.isdecimal() else DIGITS.index(ch)
    return total + (digit or 0)


def bounds(match: re.Match) -> tuple[int, int]:
    start = number(match[1])
    end = number(match[2]) if match[2] else start
    return min(start, end), max(start, end)


def parse_episode_filter(value: str | None) -> tuple[int, int] | None:
    if not value:
        return None
    match = re.fullmatch(rf"\s*第?\s*({NUMBER})\s*集?(?:\s*{DASH}\s*第?\s*({NUMBER})\s*集?)?\s*", value)
    if not match:
        raise ValueError(f"集数范围无法识别：{value}。可写 2、1-30 或第一至三十集。")
    return bounds(match)


def read_text(path: Path, source: bytes | None = None) -> str:
    if source is None:
        source = path.read_bytes()
    if path.suffix.lower() != ".docx":
        return source.decode("utf-8-sig")
    with zipfile.ZipFile(BytesIO(source)) as archive:
        root = ElementTree.fromstring(archive.read("word/document.xml"))
    paragraphs = []
    for paragraph in root.iter(W + "p"):
        parts = []
        for node in paragraph.iter():
            if node.tag == W + "t":
                parts.append(node.text or "")
            elif node.tag in (W + "br", W + "cr"):
                parts.append("\n")
            elif node.tag == W + "tab":
                parts.append("\t")
        paragraphs.append("".join(parts))
    return "\n".join(paragraphs)


def windows(lines: list[str], size: int, overlap: int) -> Iterator[str]:
    """Prefer whole lines and keep overlap inside this one scene."""
    text = "\n".join(lines)
    start = 0
    while start < len(text):
        end = min(start + size, len(text))
        if end < len(text):
            boundary = text.rfind("\n", start + max(size // 2, overlap + 1), end + 1)
            if boundary >= 0:
                end = boundary
        piece = text[start:end].strip()
        if piece:
            yield piece
        if end == len(text):
            break
        target = end - overlap
        line_end = text.find("\n", target, end)
        start = line_end + 1 if line_end >= 0 else target


def chunk_text(text: str, chunk_size: int, overlap: int, *, script: bool = True
               ) -> Iterator[tuple[str, int | None, int | None, str]]:
    lines: list[str] = []
    episode: tuple[int | None, int | None] = (None, None)
    has_heading = False
    scene = ""

    def emit():
        for piece in windows(lines, chunk_size, overlap):
            start, end = episode
            if start is None and not script:
                mentioned = [bounds(m) for m in EPISODE.finditer(piece)]
                if mentioned:
                    start = min(a for a, _ in mentioned)
                    end = max(b for _, b in mentioned)
            yield piece, start, end, scene

    for raw in text.lstrip("\ufeff").splitlines():
        line = raw.strip()
        if not line:
            continue
        heading = HEADING.match(line)
        scene_number = SCENE.match(line)
        if heading:
            yield from emit()
            lines = []
            episode, scene = bounds(heading), ""
            has_heading = True
        elif scene_number:
            # Keep an episode heading with its first scene. Only a scene-only
            # screenplay may supply a missing episode through its scene number.
            if lines and (scene or not (len(lines) == 1 and HEADING.match(lines[0]))):
                yield from emit()
                lines = []
            scene = f"{int(scene_number[1])}-{int(scene_number[2])}"
            if script and not has_heading:
                inferred = int(scene_number[1])
                episode = inferred, inferred
        lines.append(line)
    yield from emit()
