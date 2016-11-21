local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"
local babys = require "baby"

local room = {}
local data = {}
local cli = client.handler()
math.randomseed(os.time())

local cards = { 
	0, 0, 0, 0, 0,
	0, 1, 1, 1, 0,	
	0, 1, 1, 1, 0,	
	0, 1, 1, 1, 0,	
	0, 0, 0, 0, 0 
}

local function init()
	client.init("proto")()
	for i=1,#cards do
		if cards[i] > 0 then
			cards[i] = math.random(5)
		end
	end
end

local function inithandcards(c)
	c.babys = {}
	for i = 1, 5 do
		table.insert(c.babys, math.random(#babys))
	end
	c.handcards = {}
	for i = 1, 4 do
		table.insert(c.handcards, math.random(5))
	end
end

local function opponent(uid)
	for k, v in pairs(data) do
		if uid ~= k then
			return v
		end
	end
end

function cli:initroom()
	local oppo = opponent(self.uid)
	return { cards = cards, p1babys = self.babys, p1handcards = self.handcards, p2babys = oppo.babys, p2handcards = oppo.handcards }
end

function cli:drag(args)
	log("cli:drag")
	local oppo = opponent(self.uid)
	client.push(oppo, "dragdata", args)
end

local function new_user(fd, uid)
	local c = data[uid]
	c.fd, c.uid = fd, uid
	local ok, c = pcall(client.dispatch , c)
	if ok == false then
		log("fd=%d is gone. error = %s", fd, c)
		skynet.call(service.manager, "lua", "exitagent", fd, uid)
	end
end

function room.assign(fd, uid)
	skynet.fork(new_user, fd, uid)
	return true
end

function room.init(p1, p2)
	data[p1] = {}
	inithandcards(data[p1])
	data[p2] = {}
	inithandcards(data[p2])
end

service.init {
	command = room,
	info = data,
	require = {
		"manager",
	},
	init = init
}