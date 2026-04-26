local h = {}

function h.init(env)
	print("处理器初始化")
end

function h.func(key, env)
	local ctx = env.engine.context
	local is_ascii_mode = ctx:get_option("ascii_mode")
	if (not is_ascii_mode) and key:repr() == "Control+bracketleft" then
		ctx:set_option("ascii_mode", true)
		ctx.input = ""
	end
	return 2
end

return h
