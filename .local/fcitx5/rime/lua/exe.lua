--[[
网页启动器（Linux / fcitx5-rime 版，lua_translator 形式）

用法：打出下面的命令后，候选栏会出现一条“🌐 打开 xxx”，
      按空格 / 回车 / 数字键确认，才会用 xdg-open 打开网页；
      按 Esc 或删掉编码则不打开。
      候选的 text 故意留空，所以确认后不会有任何字符上屏。

  /huma /zhmn                      虎码官网
  /baidu /bddu /fuxl               百度
  /biying /bing /biyk /htxk        必应
  /guge /google /hgzz              谷歌
  /wangpan /whpj /mbia             虎码网盘
  /genda /gfda /piua /muyi /emon   虎码打字练习
  /zitong /zits /whib              字通 zi.tools
  /yedian /yedm /dnih              汉典

部署方式：schemas 的 engine/translators 里加 "- lua_translator@exe_translator"，
          rime.lua 里加 'exe_translator = require("exe")'。
]]--

local groups = {
  { name = "虎码官网", url = "https://tiger-code.com", aliases = { "/huma", "/zhmn" } },
  { name = "百度", url = "https://www.baidu.com", aliases = { "/baidu", "/bddu", "/fuxl" } },
  { name = "必应", url = "https://cn.bing.com", aliases = { "/biying", "/bing", "/biyk", "/htxk" } },
  { name = "谷歌", url = "https://www.google.com", aliases = { "/guge", "/google", "/hgzz" } },
  { name = "虎码网盘", url = "http://huma.ysepan.com", aliases = { "/wangpan", "/whpj", "/mbia" } },
  { name = "虎码打字练习", url = "https://typer.owenyang.top",
    aliases = { "/genda", "/gfda", "/piua", "/muyi", "/emon" } },
  { name = "字通", url = "https://zi.tools", aliases = { "/zitong", "/zits", "/whib" } },
  { name = "汉典", url = "http://www.yedict.com", aliases = { "/yedian", "/yedm", "/dnih" } },
}

local lookup = {}
for _, group in ipairs(groups) do
  for _, alias in ipairs(group.aliases) do
    lookup[alias] = group
  end
end

local function open_url(url)
  -- 后台执行，避免阻塞输入法主线程；失败也不影响打字
  os.execute('xdg-open "' .. url .. '" >/dev/null 2>&1 &')
end

local pending_url = nil

local function init(env)
  pending_url = nil
  -- 确认候选（上屏）时才真正打开网页；普通上屏时 pending_url 是空的，不会误触
  env.connection = env.engine.context.commit_notifier:connect(function(ctx)
    local url = pending_url
    pending_url = nil
    if url then open_url(url) end
  end)
end

local function fini(env)
  if env.connection then
    env.connection:disconnect()
    env.connection = nil
  end
  pending_url = nil
end

local function translator(input, seg)
  local group = lookup[input]
  if not group then
    pending_url = nil
    return
  end
  pending_url = group.url
  yield(Candidate("exe_launcher", seg.start, seg._end, "", "🌐 打开" .. group.name))
end

return { init = init, fini = fini, func = translator }
