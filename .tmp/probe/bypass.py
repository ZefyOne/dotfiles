#!/usr/bin/env python3
import re, sys, time, urllib.parse, urllib.request, http.cookiejar

HOST = "https://ddd.jichang.best"
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"

cj = http.cookiejar.CookieJar()
op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
op.addheaders = [("User-Agent", UA), ("Accept", "text/html,application/xhtml+xml")]


def get(url=None):
    url = url or HOST + "/"
    with op.open(url, timeout=20) as r:
        return r.status, r.read().decode("utf-8", "replace")


def cookie_val(name):
    for c in cj:
        if c.name == name:
            return urllib.parse.unquote(c.value)
    return None


def do_challenge(html):
    nonce = int(re.search(r'var nonce = (\d+)', html).group(1))
    val = cookie_val("fl_ua_p")
    if not val:
        return False
    d = 12345
    for i, ch in enumerate(val):
        if re.fullmatch(r"[a-zA-Z0-9]", ch):
            d += ord(ch) * (nonce + i)
    body = urllib.parse.urlencode({"sum": d, "nonce": nonce}).encode()
    req = urllib.request.Request(HOST + "/", data=body, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    req.add_header("X-FL-UA-Step", "prev")
    with op.open(req, timeout=20) as r:
        r.read()
    return True


status, html = get()
for attempt in range(4):
    if "Checking your Browser" not in html:
        break
    print(f"[{attempt}] challenge page, solving", file=sys.stderr)
    if not do_challenge(html):
        break
    time.sleep(1.2)
    status, html = get()

print(f"# status={status} len={len(html)}", file=sys.stderr)
print(html)
