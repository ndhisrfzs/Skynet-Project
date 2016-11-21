local skynet = require "skynet"
local service = require "service"
local log = require "log"

local match = {}
local users = {}
local tmpuser = {}
local match_response = {}

local function new_room()
	return skynet.newservice "room"
end

local function match_users()
	while true do
		if #users >= 2 then
			local room = new_room()
			local player1 = table.remove(users, 1)
			local player2 = table.remove(users, 1)

			skynet.call(room, "lua", "init", player1.uid, player2.uid)

			local response = match_response[player1.uid]
			match_response[player1.uid] = nil
			users[player1.uid] = nil
			tmpuser[player1.uid] = nil
			response(true, player2.data, room)

			response = match_response[player2.uid]
			match_response[player2.uid] = nil
			users[player2.uid] = nil
			tmpuser[player2.uid] = nil
			response(true, player1.data, room)
		else
			skynet.sleep(100)	-- sleep 10 min
		end
	end
end

function match.matching(uid, data)
	if tmpuser[uid] == nil then
		tmpuser[uid] = true
		match_response[uid] = skynet.response()
		table.insert(users, { uid = uid, data = data })
		return service.NORET
	else
		return false
	end
end

local function init()
	skynet.fork(match_users)
end

service.init {
	command = match,
	init = init
}
