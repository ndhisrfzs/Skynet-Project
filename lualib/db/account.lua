local account = {}
local handler

function account.init(ch)
	handler = ch	
end

local function make_key(account)
	return handler(account), string.format("account:%s", account)
end

local function tochange(tab)
	local new_tab = {}
	for i = 1,#tab,2 do
		new_tab[tab[i]] = tab[i + 1]
	end
	return new_tab
end

function account.load(account)
	local ret = { account = account }
	local db, key = make_key(account)
	if db:exists(key) then
		ret = db:hgetall(key):tokv()
	end

	return ret
end

function account.create(account, password)
	if account and password and #account < 24 and #password < 24 == false then
		return false
	end

	local db, key = make_key(account)
	if db:hsetnx(key, "account", account) == 0 then
		return false
	end

	local uid = db:hincrby("primary", "account", 1)

	db:hmset(key, "password", password)
	db:hmset(key, "uid", uid)

	return true
end

return account