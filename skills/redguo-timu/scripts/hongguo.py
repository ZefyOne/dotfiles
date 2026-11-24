#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""hongguo.py — 红果榜单 / 剧集详情 / 番茄 IP 池 取数工具。

子命令:
    digest               取榜单并输出题材分析摘要（选题卡的前置数据）
    detail <sid> [...]   取剧集详情（简介/演员/集数/备案）
    fanqie [n]           取番茄小说榜 IP 池（书名/作者/简介）

数据源:
    榜单  https://hongguoduanju.com/rank/<board>
    详情  https://hongguoduanju.com/detail?series_id=<sid>
    上游  https://fanqienovel.com/api/rank/list

降级: 网络失败时读 snapshots/ 下最新快照，并在输出顶部标注 STALE。
"""
import argparse
import collections
import datetime
import json
import os
import re
import sys
import tempfile
import time
import urllib.request
from pathlib import Path

BASE = "https://hongguoduanju.com"
FANQIE = "https://fanqienovel.com/api/rank/list"
UA = ("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 "
      "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1")
HERE = Path(__file__).resolve().parent
SKILL_DIR = HERE.parent
APP_NAME = "redguo-timu"
CACHE_TTL = 6 * 3600

BOARDS = {
    "new": "new-drama",          # 新剧榜：上架 3 天内，选题雷达
    "hot": "hot-drama",          # 热播榜：全站混排
    "real": "hot-real-drama",    # 真人剧
    "ai": "hot-ai-drama",        # AI剧
    "comic": "hot-comic-drama",  # 漫剧
}
# 这四类不是题材，是载体/形态，统计题材时要单列
CARRIER_TAGS = {"漫剧", "AI剧", "真人剧", "小说漫改", "现代", "小说"}


# ---------------------------------------------------------------- 基础设施

def _platform_cache_root() -> Path:
    """各系统的规范缓存根目录。"""
    if sys.platform == "win32":
        base = os.environ.get("LOCALAPPDATA") or os.environ.get("APPDATA")
        return Path(base) if base else Path.home() / "AppData" / "Local"
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Caches"
    base = os.environ.get("XDG_CACHE_HOME")
    return Path(base) if base else Path.home() / ".cache"


def cache_dir() -> Path:
    """REDGUO_CACHE > 系统规范路径 > 系统临时目录。不再落在 skill 目录里。"""
    override = os.environ.get("REDGUO_CACHE")
    try:
        d = Path(override) if override else _platform_cache_root() / APP_NAME
        d.mkdir(parents=True, exist_ok=True)
        probe = d / ".write_test"
        probe.write_text("", encoding="utf-8")
        probe.unlink()
        return d
    except OSError:
        d = Path(tempfile.gettempdir()) / APP_NAME
        d.mkdir(parents=True, exist_ok=True)
        return d


def snapshots_dir() -> Path:
    return SKILL_DIR / "snapshots"


def http_get(url: str, timeout=25) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": UA,
                                               "Accept-Language": "zh-CN,zh;q=0.9"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    return raw.decode("utf-8", errors="replace")


def cached_get(url: str) -> str:
    name = re.sub(r"[^a-zA-Z0-9]+", "_", url)[-120:] + ".html"
    p = cache_dir() / name
    if p.exists() and time.time() - p.stat().st_mtime < CACHE_TTL:
        return p.read_text(encoding="utf-8", errors="ignore")
    text = http_get(url)
    p.write_text(text, encoding="utf-8")
    time.sleep(1.0)  # 对源站保持礼貌
    return text


def json_array_after(html: str, key: str):
    """从 Next.js flight 数据里取出 "key":[...] 并解析。"""
    i = html.find('"%s":[' % key)
    if i < 0:
        return []
    s = html.index("[", i)
    depth, in_str, esc = 0, False, False
    for k in range(s, len(html)):
        c = html[k]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            continue
        if c == '"':
            in_str = True
        elif c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                try:
                    return json.loads(html[s:k + 1])
                except json.JSONDecodeError:
                    return []
    return []


def json_object_after(html: str, key: str):
    i = html.find('"%s":{' % key)
    if i < 0:
        return None
    s = html.index("{", i)
    depth, in_str, esc = 0, False, False
    for k in range(s, len(html)):
        c = html[k]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            continue
        if c == '"':
            in_str = True
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                try:
                    return json.loads(html[s:k + 1])
                except json.JSONDecodeError:
                    return None
    return None


# ---------------------------------------------------------------- 取数

def fetch_board(key: str):
    """返回 (rows, updated_text)。"""
    html = cached_get(f"{BASE}/rank/{BOARDS[key]}")
    rows = json_array_after(html, "rankList")
    m = re.search(r'"updatedText":"((?:[^"\\]|\\.)*)"', html)
    upd = ""
    if m:
        try:
            upd = json.loads('"' + m.group(1) + '"')
        except json.JSONDecodeError:
            upd = m.group(1)
    return rows, upd


CORPUS_PAGES = [f"category/{c}?page={p}" for c in ("real-drama", "comic") for p in (1, 2, 3)]


def collect_corpus():
    """分类页语料：标签最全，用于要素矩阵与组合空位。"""
    items = {}
    for path in CORPUS_PAGES:
        try:
            html = cached_get(f"{BASE}/{path}")
        except Exception as e:  # noqa: BLE001
            print(f"!! 分类页 {path} 失败: {e}", file=sys.stderr)
            continue
        for it in json_array_after(html, "recommendList"):
            if it.get("series_id"):
                items[it["series_id"]] = it
    return items


def collect_all():
    data, meta = {}, {}
    for key in BOARDS:
        try:
            rows, upd = fetch_board(key)
            if rows:
                data[key] = rows
                meta[key] = upd
        except Exception as e:  # noqa: BLE001
            print(f"!! 榜单 {key} 抓取失败: {e}", file=sys.stderr)
    if not data:
        return None, {}
    return data, meta


def save_snapshot(data, corpus=None):
    d = snapshots_dir()
    try:
        d.mkdir(parents=True, exist_ok=True)
        day = datetime.date.today().isoformat()
        payload = {"boards": data, "corpus": corpus or {}}
        (d / f"{day}.json").write_text(
            json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    except OSError:
        pass


def load_latest_snapshot():
    """返回 (boards, corpus, 日期)。兼容不含 corpus 的旧快照。"""
    d = snapshots_dir()
    if not d.exists():
        return None, None, None
    files = sorted(d.glob("*.json"))
    if not files:
        return None, None, None
    f = files[-1]
    try:
        payload = json.loads(f.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None, None, None
    if isinstance(payload, dict) and "boards" in payload:
        return payload.get("boards"), payload.get("corpus") or {}, f.stem
    return payload, {}, f.stem


# ---------------------------------------------------------------- 统计

def norm(r: dict) -> dict:
    """榜单（驼峰）与分类页（下划线）字段名不同，统一成一套。"""
    return {
        "sid": r.get("seriesId") or r.get("series_id"),
        "title": r.get("title") or r.get("series_name") or "",
        "heat": r.get("heatText") or "",
        "score": r.get("scoreText") or "",
        "tags": r.get("tags") or [],
        "ep": r.get("episodeCount") or r.get("episode_cnt"),
        "intro": r.get("series_intro") or r.get("description") or "",
    }



def tag_stats(rows):
    """要素频次（剔除角色名与载体类标签）。"""
    c = collections.Counter()
    for r in rows:
        for t in norm(r)["tags"]:
            if "·" in t or t in CARRIER_TAGS:
                continue
            c[t] += 1
    return c


def carrier_stats(rows):
    """载体分布：漫剧 / AI剧 / 真人剧（取首个标签）。"""
    c = collections.Counter()
    for r in rows:
        tags = norm(r)["tags"]
        if tags and tags[0] in ("漫剧", "AI剧", "真人剧"):
            c[tags[0]] += 1
    return c


def episode_quantiles(rows):
    eps = sorted(e for e in (norm(r)["ep"] for r in rows) if e)
    if not eps:
        return None
    n = len(eps)
    return {"n": n, "p25": eps[n // 4], "median": eps[n // 2],
            "p75": eps[3 * n // 4], "max": eps[-1]}


def combination_gaps(tag_counter, rows, top_genres=8, top_elems=10):
    """题材 × 要素 的组合空位：要素 E 还没在这些题材里出现过。"""
    genres = [g for g, _ in tag_counter.most_common(80) if g in GENRES][:top_genres]
    elems = [e for e, _ in tag_counter.most_common(120) if e not in GENRES][:top_elems]
    used = collections.defaultdict(set)
    for r in rows:
        ts = set(norm(r)["tags"])
        gs, es = ts & set(genres), ts & set(elems)
        for e in es:
            used[e] |= gs
    out = []
    for e in elems:
        free = [g for g in genres if g not in used[e]]
        if free:
            out.append((e, free))
    return out


# 红果官方 24 个分类（取自站点 selector 列表）
GENRES = {"爱情", "年代", "逆袭", "传奇", "成长", "家庭", "家族", "萌宝", "悬疑",
          "惊悚", "恐怖", "志怪", "古装", "玄幻", "奇幻", "都市", "青春", "喜剧",
          "科幻", "灾难", "动作冒险", "战争", "综艺", "剧情"}


def fmt_row(i, r):
    d = norm(r)
    tags = [t for t in d["tags"] if "·" not in t][:3]
    return "| {} | {} | {} | {} | {} | {}集 |".format(
        i, d["title"], d["heat"], (d["score"] or "—").replace("分", ""),
        "/".join(tags), d["ep"] or "?")


def cmd_digest(args):
    data, meta = collect_all()
    stale = None
    corpus = {}
    if data is None:
        data, corpus, stale = load_latest_snapshot()
        if data is None:
            print("ERROR: 榜单抓取失败，且没有可用快照。请让用户截图或稍后重试。",
                  file=sys.stderr)
            return 2
    else:
        corpus = collect_corpus()
        save_snapshot(data, corpus)

    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    head = [f"# 红果榜单数据 {now}"]
    if stale:
        head.append(f"\n> **STALE**：实时抓取失败，以下为 {stale} 的快照，热度可能过期。")
    if meta.get("new"):
        head.append(f"\n新剧榜口径：{meta['new']}")

    merged = dict(corpus)
    for rows in data.values():
        for r in rows:
            merged.setdefault(r["seriesId"], r)
    all_rows = list(merged.values())
    tag_c = tag_stats(all_rows)
    print("\n".join(head))
    print(f"\n语料：榜单 {sum(len(v) for v in data.values())} 条 / 去重 {len(merged)} 部"
          f"（其中分类页 {len(corpus)} 部带完整标签）")

    limit = args.limit
    for key, label in (("new", "新剧榜（上架3天内）"), ("hot", "热播榜"),
                       ("real", "真人剧榜"), ("ai", "AI剧榜"), ("comic", "漫剧榜")):
        rows = data.get(key) or []
        if not rows:
            continue
        print(f"\n## {label} Top{min(limit, len(rows))}")
        print("\n| # | 剧名 | 热度 | 评分 | 标签 | 集数 |")
        print("|---|---|---|---|---|---|")
        for i, r in enumerate(rows[:limit], 1):
            print(fmt_row(i, r))

    q = episode_quantiles(all_rows)
    if q:
        print(f"\n## 集数约束\n\nn={q['n']}　p25={q['p25']}　中位={q['median']}"
              f"　p75={q['p75']}　max={q['max']}")
    carrier = carrier_stats(all_rows)
    if carrier:
        total = sum(carrier.values()) or 1
        print(f"\n## 载体分布（有载体标签的 {total} 部）\n\n" + "　".join(
            f"{k} {v}部({v * 100 // total}%)" for k, v in carrier.most_common()))

    print("\n## 要素频次 Top20\n")
    print("　".join(f"{t}{c}" for t, c in tag_c.most_common(20)))

    gaps = combination_gaps(tag_c, all_rows)
    if gaps:
        print("\n## 组合空位（该要素未在这些题材里出现过）\n")
        for e, free in gaps[:8]:
            print(f"- **{e}** × {' / '.join(free[:6])}")

    print("\n## 官方分类（24）\n")
    print("　".join(sorted(GENRES)))
    return 0


def wan(v):
    try:
        n = int(v)
    except (TypeError, ValueError):
        return str(v)
    return f"{n / 10000:.1f}万" if n >= 10000 else str(n)


def cmd_find(args):
    """在本地语料（榜单+分类页）里按关键词捞剧。"""
    corpus = collect_corpus()
    data, _ = collect_all()
    rows = list(corpus.values()) + [r for v in data.values() for r in v]
    seen, out = set(), []
    for r in rows:
        d = norm(r)
        sid = d["sid"]
        if not sid or sid in seen:
            continue
        seen.add(sid)
        hay = " ".join([d["title"], " ".join(d["tags"]), d["intro"]])
        if any(kw in hay for kw in args.keywords):
            out.append(d)
    if not out:
        print("（本地语料未命中，改用 web_search site:hongguoduanju.com <题材>）")
        return 1
    print(f"# 本地语料命中 {len(out)} 部（关键词：{'/'.join(args.keywords)}）\n")
    print("| seriesId | 剧名 | 集数 | 标签 |")
    print("|---|---|---|---|")
    for d in out[:args.limit]:
        tags = [t for t in d["tags"] if "·" not in t][:4]
        print(f"| {d['sid']} | {d['title']} | {d['ep'] or '?'} | {'/'.join(tags)} |")
    return 0


def cmd_detail(args):
    out = []
    for sid in args.ids:
        try:
            html = cached_get(f"{BASE}/detail?series_id={sid}")
        except Exception as e:  # noqa: BLE001
            print(f"!! {sid} 抓取失败: {e}", file=sys.stderr)
            continue
        d = json_object_after(html, "seriesDetail")
        if not d:
            print(f"!! {sid} 未找到 seriesDetail", file=sys.stderr)
            continue
        fav = re.search(r'"series_favorite_count":"?(\d+)"?', html)
        like = re.search(r'"series_like_count":"?(\d+)"?', html)
        out += [f"### {d.get('series_name')}", "",
                f"- 集数：{d.get('episode_cnt')}（免费开放前 {d.get('accessible_episode_cnt')} 集）",
                f"- 标签：{' / '.join(d.get('tags') or [])}"]
        if fav or like:
            out.append("- 收藏 {} / 点赞 {}".format(
                wan(fav.group(1)) if fav else "?", wan(like.group(1)) if like else "?"))
        if d.get("first_visible_time"):
            out.append("- 上线：" + datetime.datetime.fromtimestamp(
                int(d["first_visible_time"])).strftime("%Y-%m-%d"))
        if d.get("record_number"):
            out.append(f"- 备案：{d['record_number']}")
        out += ["", "**简介**：" + (d.get("series_intro") or "（无）"), ""]
        cast = [c for c in (d.get("celebrities") or []) if c.get("nickname")]
        if cast:
            out.append("**演员**：" + "；".join(
                f"{c['nickname']}{('（' + c['sub_title'] + '）') if c.get('sub_title') else ''}"
                for c in cast))
        else:
            out.append("**演员**：官方未标注（漫剧/AI剧）")
        out.append("")
    print("\n".join(out))
    return 0


def cmd_fanqie(args):
    try:
        raw = http_get(FANQIE)
        payload = json.loads(raw)
    except Exception as e:  # noqa: BLE001
        print(f"!! 番茄榜单抓取失败: {e}", file=sys.stderr)
        return 2
    books = (payload.get("data") or {}).get("list") or []
    print(f"# 番茄小说榜 IP 池（{len(books)} 条）\n")
    for b in books[:args.n]:
        print(f"## {b.get('bookName', '?')}　—　{b.get('author', '')}")
        abstract = (b.get("abstract") or "").replace("\n", " ").strip()
        print(f"{abstract[:220]}\n")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    d = sub.add_parser("digest", help="榜单 + 题材分析")
    d.add_argument("--limit", type=int, default=10, help="每榜条数，默认 10")
    d.set_defaults(func=cmd_digest)
    fd = sub.add_parser("find", help="本地语料按关键词捞剧")
    fd.add_argument("keywords", nargs="+")
    fd.add_argument("--limit", type=int, default=20)
    fd.set_defaults(func=cmd_find)
    dt = sub.add_parser("detail", help="剧集详情")
    dt.add_argument("ids", nargs="+")
    dt.set_defaults(func=cmd_detail)
    f = sub.add_parser("fanqie", help="番茄 IP 池")
    f.add_argument("n", nargs="?", type=int, default=10)
    f.set_defaults(func=cmd_fanqie)
    args = ap.parse_args()
    rc = args.func(args)
    if args.cmd in ("digest", "find", "detail"):
        print(f"\n缓存目录：{cache_dir()}")
    sys.exit(rc)


if __name__ == "__main__":
    main()
