local skynet = require "skynet"
local service = require "service"
local log = require "log"

local manager = {}
local users = {}

local function new_agent()
	-- todo: use a pool
	return skynet.newservice "agent"
end

local function free_agent(agent)
	-- kill agent, todo: put it into a pool maybe better
	skynet.kill(agent)
end

function manager.assign(fd, uid)
	local agent
	repeat
		agent = users[uid]
		if not agent then
			agent = new_agent()
			if not users[uid] then
				-- double check
				users[uid] = agent
			else
				free_agent(agent)
				agent = users[uid]
			end
		end
	until skynet.call(agent, "lua", "assign", fd, uid)
	log("Assign %d to %s [%s]", fd, uid, agent)
end

function manager.exit(uid)
	users[uid] = nil
end

service.init {
	command = manager,
	info = users,
}


