local skynet = require "skynet"
local socket = require "socket"
local proxy = require "socket_proxy"
local log = require "log"
local service = require "service"

local hub = {}
local data = { socket = {} }

local function auth_socket(fd)
	return skynet.call(service.auth, "lua", "shakehand" , fd)
end

local function assign_agent(fd, uid)
	skynet.call(service.manager, "lua", "assign", fd, uid)
end

function new_socket(fd, addr)
	data.socket[fd] = "[AUTH]"
	proxy.subscribe(fd)
	local ok , uid =  pcall(auth_socket, fd)
	if ok and uid then
		data.socket[fd] = uid
		if pcall(assign_agent, fd, uid) then
			return	-- succ
		else
			log("Assign failed %s to %s", addr, uid)
		end
	else
		log("Auth faild %s", addr)
	end
	proxy.close(fd)
	data.socket[fd] = nil
end

function hub.open(ip, port)
	log("Listen %s:%d", ip, port)
	assert(data.fd == nil, "Already open")
	data.fd = socket.listen(ip, port)
	data.ip = ip
	data.port = port
	socket.start(data.fd, new_socket)
end

function hub.close()
	assert(data.fd)
	log("Close %s:%d", data.ip, data.port)
	socket.close(data.fd)
	data.ip = nil
	data.port = nil
end

service.init {
	command = hub,
	info = data,
	require = {
		"auth",
		"manager",
	}
}
