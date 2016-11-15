local skynet = require "skynet"
local service = require "service"
local log = require "log"

local roles = {}
local data = {}

local index = 0
function roles.newname()
	index = index + 1
	return '天赐'..tostring(index)
end

service.init {
	command = roles,
	info = data,
}