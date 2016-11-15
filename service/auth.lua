local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"

local auth = {}
local cli = client.handler()

local SUCC = { ok = true }
local FAIL = { ok = false }

function cli:login(args)
	log("login username = %s", args.username)
	local user = skynet.call(service.database, "lua", "data", "account", "load", args.username)
	if user.password == args.password then
		self.uid = user.uid
		self.exit = true
		return SUCC
	else
		return FAIL
	end
end

function cli:register(args)
	log("register username = %s", args.username)
	local ok = skynet.call(service.database, "lua", "data", "account", "create", args.username, args.password) 
	if ok then
		return SUCC
	else
		return FAIL
	end
end

function cli:ping()
	log("ping")
end

function auth.shakehand(fd)
	local ok, c = pcall(client.dispatch, { fd = fd })
	return c.uid
end

service.init {
	command = auth,
	require = {
		"database",
	},
	init = client.init "proto",
}
