module("luci.controller.kikiauth.authserver", package.seeall)

-- Name of iptable chain, in which we will open access
-- to OAuth services (Facebook, Google).
-- This chain will be in NAT table and FILTER table.
local chain = "WiFiDog_eth0_OAuthServices"


-- === String utilities ====

-- Remove leading and trailing whitespaces from string
function string:strip()
	local t = self:gsub("^ +", "")
	t = t:gsub(" +$", "")
	return t
end

-- Check if a string starts with given prefix
function string.startswith(self, prefix)
	local ret = false
	if prefix ~= nil then
		ret = (self:sub(1, string.len(prefix)) == prefix)
	end
	return ret
end

-- Check if a string ends with given suffix
function string.endswith(self, suffix)
	local ret = false
	if suffix ~= nil then
		local offset = self:len() - suffix:len()
		ret = (self:sub(offset + 1) == suffix)
	end
	return ret
end

function index()
    entry({"kikiauth", "ping"}, call("action_say_pong"), "Click here", 10).dependent=false
    entry({"kikiauth", "auth"}, call("action_auth_response_to_gw"), "", 20).dependent=false
    entry({"kikiauth", "portal"}, call("action_redirect_to_success_page"), "Success page", 30).dependent=false
    entry({"kikiauth", "login"}, template("kikiauth/login"), "Login page", 40).dependent=false
    entry({"kikiauth", "oauth", "googlecallback"}, template("kikiauth/googlecallback"), "", 50).dependent=false
    entry({"kikiauth", "oauth", "facebookcallback"}, template("kikiauth/facebookcallback"), "", 60).dependent=false
end

function action_say_pong()
    luci.http.prepare_content("text/plain")
    luci.http.write("Pong")
end

function action_redirect_to_success_page()
    luci.http.redirect("http://mbm.vn")
end

function action_auth_response_to_gw()
    local token = luci.http.formvalue("token")
    local url = "https://graph.facebook.com/me?access_token=%s" % {token}
    local response
    local wget = assert(io.popen("wget --no-check-certificate -qO- %s" % {url}))
    if wget then
        response = wget:read("*all")
        wget:close()
    end

    if string.find(response,"id",1)~=nil then
        luci.http.write("Auth: 1")
    else
        luci.http.write("Auth: 6")
    end
end

-- Get IP list for an OAuth service.
-- @param service "facebook" or "google"
function get_oauth_ip_list(service)
	local x = luci.model.uci.cursor()
	local lip = x:get_list('kikiauth', 'facebook', 'ips')
	local allip = {}
	-- Convert from hostname (www-slb-10-01-prn1.facebook.com)
	-- to IP.
	for n, ip in ipairs(lip) do
		-- Check if ip is a hostname
		if not ip:match('^%d+.%d+.%d+.%d+$') then
			allip = extendtable(allip, hostname_to_ips(ip))
		else
			table.insert(allip, ip)
		end
	end
	return allip
end

function hostname_to_ips(host)
	local l = {}
	local rs = nixio.getaddrinfo(host, 'inet', 'https')
	if not rs then
		return l;
	end
	for i, r in pairs(rs) do
		if r.socktype == 'stream' then table.insert(l, r.address) end
	end
	return l
end

function extendtable(t1, t2)
	for i, v in pairs(t2) do
		table.insert(t1, v)
	end
	return t1
end

function iptables_open_access()

end

function iptables_kikiauth_chain_exist()
	return (iptables_kikiauth_chain_exist_in_table('nat')
	        and iptables_kikiauth_chain_exist_in_table('filter'))
end

function iptables_kikiauth_chain_exist_in_table(tname)
	local count = 0
	for line in luci.util.execi("iptables-save -t %s | grep %s" % {tname, chain}) do
		line = line:strip()
		if count == 0 and line:startswith(":%s" % {chain}) then
			count = count + 1
		elseif count == 1 and line:endswith("-j %s" % {chain}) then
			count = count + 1
		end
	end      -- If check OK, count == 2 now
	return (count > 1)
end