local skynet = require "skynet"
local log = require "log"

local service = { NORET = {} } 

function service.init(mod)
	local funcs = mod.command
	if mod.info then
		skynet.info_func(function()
			return mod.info
		end)
	end
	skynet.start(function()
		if mod.require then
			local s = mod.require
			for _, name in ipairs(s) do
				service[name] = skynet.uniqueservice(name)
			end
		end
		if mod.init then
			mod.init()
		end
		skynet.dispatch("lua", function (_,_, cmd, ...)
			local f = funcs[cmd]
			if f then
				local r = f(...)
				if r ~= service.NORET then
					skynet.ret(skynet.pack(r))
				end
			else
				log("Unknown command : [%s]", cmd)
				skynet.response()(false)
			end
		end)
	end)
end

return service
