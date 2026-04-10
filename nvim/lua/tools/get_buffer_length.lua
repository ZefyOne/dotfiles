local M = {}
local function removeWhitespaceAndSpecialChars(input)
  local pattern = "%s"
  local result = string.gsub(input, pattern, "")
  return result
end
local function utf8_len(s)
  local len = 0
  local i = 1
  while i <= #s do
    local c = string.byte(s, i)
    local cl = 1
    if c > 0 and c <= 127 then
      cl = 1
    elseif c >= 194 and c <= 223 then
      cl = 2
    elseif c >= 224 and c <= 239 then
      cl = 3
    elseif c >= 240 and c <= 244 then
      cl = 4
    end
    i = i + cl
    len = len + 1
  end
  return len
end

function M.setup(content)
  -- 移除空白字符
  local result = removeWhitespaceAndSpecialChars(content)
  -- 返回字符串长度
  return utf8_len(result)
end

return M
