local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"

local agent = {}
local data = {}
local cli = client.handler()

local SUCC = { ok = true }
local FAIL = { ok = false }

function cli:set(args)
	log("set %s=%s", args.what, args.value)
end

function cli:rolename()
	return { rolename = skynet.call(service.roles, "lua", "newname") }
end

function cli:rolecreate(args)
	log("rolecreate uid = %s rolename=%s sex=%d", data.uid, args.rolename, args.sex)
	local ret = skynet.call(service.database, "lua", "data", "role", "create", data.uid, args.rolename, args.sex)
	if ret then
		return SUCC
	else
		return FAIL
	end
end

function cli:rolelogin()
	assert(not self.login)
	if data.fd then
		log("login fail %s fd=%d", data.uid, self.fd)
		return FAIL
	end
	local ret = skynet.call(service.database, "lua", "data", "role", "load", data.uid)
	if ret.ok then
		self.login = ret.ok
		data.fd = self.fd
		log("login succ %s fd=%d", data.uid, self.fd)
	end
	return ret
end

function cli:matching()
	local role = skynet.call(service.database, "lua", "data", "role", "load", data.uid)
	local ret, room = skynet.call(service.match, "lua", "matching", data.uid, role)
	if ret == false then
		return FAIL
	else
		self.exit = true
		self.room = room
		return ret
	end
end

local function exit(fd)
	client.close(fd)
	if data.fd == fd then
		data.fd = nil
		skynet.sleep(3000)	-- exit after 10s
		if data.fd == nil then
			-- double check
			if not data.exit then
				data.exit = true	-- mark exit
				skynet.call(service.manager, "lua", "exit", data.uid)	-- report exit
				log("user %s afk", data.uid)
				skynet.exit()
			end
		end
	end
end

local function new_user(fd)
	local ok, c = pcall(client.dispatch , { fd = fd })
	if ok == false then
		log("fd=%d is gone. error = %s", fd, c)
		exit(fd)
	else
		skynet.call(c.room, "lua", "assign", data.fd, data.uid)
	end
end

function agent.assign(fd, uid)
	if data.exit then
		return false
	end
	if data.uid == nil then
		data.uid = uid
	end
	assert(data.uid == uid)
	skynet.fork(new_user, fd)
	return true
end

function agent.exit(fd)
	skynet.fork(exit, fd)
end

service.init {
	command = agent,
	info = data,
	require = {
		"manager",
		"database",
		"roles",
		"match"
	},
	init = client.init "proto",
}

