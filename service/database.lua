local skynet = require "skynet"
local service = require "service"
local redis = require "redis"

local db
local cmd = {}
local data = {}
local MODULE = {}

local function connect(key)
	return db
end

local function module_init(name)
	MODULE[name] = require("db."..name)
	MODULE[name].init(connect)
end

local function init()
	db = redis.connect {
        host = "127.0.0.1",
        port = 6379,
        db   = 0,
    }

    module_init("account")
    module_init("role")
end

function cmd.data(mod, cmd, ...)
	local m = MODULE[mod]
	if not m then
		return
	end

	local f = m[cmd]
	if not f then
		return
	end

	return f(...)
end

service.init {
	command = cmd,
	info = db,
	init = init
}
