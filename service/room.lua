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
local p1babys = {}
local p1handcards = {}
local p2babys = {}
local p2handcards = {}


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

function cli:initroom()
	return { cards = cards, p1babys = p1babys, p1handcards = p1handcards, p2babys = p2babys, p2handcards = p2handcards }
end

local function new_user(fd, uid)
	local c = { fd = fd, uid = uid }
	data[uid] = c
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

service.init {
	command = room,
	info = data,
	require = {
		"manager",
	},
	init = init
}