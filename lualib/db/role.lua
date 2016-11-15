local role = {}
local handler

function role.init(ch)
	handler = ch	
end

local function make_key(uid)
	return handler(uid), string.format("role:%d", uid)
end

function role.create(uid, rolename, sex)
	if uid and rolename and sex and #rolename < 12 == false then
		return false
	end

	local db, key = make_key(uid)
	if db:hsetnx(key, "uid", uid) == 0 then
		return false
	end

	db:hmset(key, "rolename", rolename)
	db:hmset(key, "sex", sex)

	return true
end

function role.load(uid)
	local ret = {}
	local db, key = make_key(uid)
	if db:exists(key) then
		ret = db:hgetall(key):tokv()
		ret.ok = true
	else
		ret.ok = false
	end

	return ret
end

return role