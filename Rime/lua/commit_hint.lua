local M = {}

local kNoop = 2

local function shortest_code(env, ch)
  local result = env.reverse:lookup(ch)
  if not result or result == "" then return nil end
  local best = nil
  for code in result:gmatch("%S+") do
    if not best or #code < #best then best = code end
  end
  return best
end

local function notify(text, code)
  local msg = string.format("%s → %s", text, code)
  os.execute(string.format(
    [[osascript -e 'display notification "%s" with title "簡碼提示"' >/dev/null 2>&1 &]],
    msg))
end

local function utf8_chars(s)
  local chars = {}
  for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    chars[#chars + 1] = ch
  end
  return chars
end

function M.init(env)
  env.reverse = ReverseLookup("liur.extended")
  env.last_input = ""
  local ctx = env.engine.context
  -- commit 時 input 可能已被清空，先在每次更新時記下來
  env.update_conn = ctx.update_notifier:connect(function(c)
    if c.input and c.input ~= "" then
      env.last_input = c.input
    end
  end)
  env.commit_conn = ctx.commit_notifier:connect(function(c)
    local text = c:get_commit_text()
    local input = env.last_input
    env.last_input = ""
    if not text or text == "" or not input or input == "" then return end
    local chars = utf8_chars(text)
    if #chars ~= 1 or #input < 2 then return end
    if not env.engine.context:get_option("commit_hint") then return end
    local best = shortest_code(env, chars[1])
    if best and #best < #input then
      notify(text, best)
    end
  end)
end

function M.fini(env)
  if env.update_conn then env.update_conn:disconnect() end
  if env.commit_conn then env.commit_conn:disconnect() end
end

function M.func(key, env)
  return kNoop
end

return M
