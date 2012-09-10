module("luci.controller.kikiauth.authserver", package.seeall)

require "luci.json"

-- Name of iptable chain, in which we will open access
-- to OAuth services (Facebook, Google).
-- This chain will be in NAT table and FILTER table.
local chain = "KikiAuth"


-- === String utilities ====

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
	entry({"kikiauth", "gw_message.php"}, template("kikiauth/gatewaymessage"), "", 70).dependent=false
end

function action_say_pong()
	luci.http.prepare_content("text/plain")
	luci.http.write("Pong")
	local enabled_OAuth_service_list = get_enabled_OAuth_service_list()
	check_ip_list_of_enabled_OAuth_services(enabled_OAuth_service_list)
	--find and add new ip
	for i=1, #enabled_OAuth_service_list do
		find_and_add_new_IP(enabled_OAuth_service_list[i])
	end
end

function get_enabled_OAuth_service_list()
	local uci = require "luci.model.uci".cursor()
	local enabled_OAuth_service_list = {}
	local function check_service_enabled(sect)
		if sect.enabled == '1' then
			local name = sect['.name']
			table.insert(enabled_OAuth_service_list, name)
		end
	end
	uci:foreach("kikiauth", "oauth_services", check_service_enabled)
	return enabled_OAuth_service_list
end

function find_and_add_new_IP(service)
	local dynamic_domains = {}  -- List of domains which has IP changing by time.
	if service == "facebook" then
		dynamic_domains = {'www.facebook.com', 's-static.ak.fbcdn.net'}
	end
	-- Currently, just Facebook has variable IPs. Other services will be defined later.

	-- No domain, do nothing
	if dynamic_domains == {} then return end

	local ips = get_oauth_ip_list(service)
	for _, d in ipairs(dynamic_domains) do
		local output = luci.sys.exec("ping -c 1 %s | grep 'bytes from' | awk '{print $4}'" % {d})
		-- The output is like "77.77.77.77:"
		-- Note that this is the output of ping command on OpenWrt. On other distro (Ubuntu),
		-- it may be different.
		if output then
			local ping_ip = luci.util.trim(output):sub(1, -2)
			if not luci.util.contains(ips, ping_ip) then
				table.insert(ips, ping_ip)
				iptables_kikiauth_add_iprule(ping_ip)
			end
		end
	end

	local uci = luci.model.uci.cursor()
	uci:set_list("kikiauth", service, "ips", ips)
	uci:save("kikiauth")
	uci:commit("kikiauth")
end

-- the following code is for checking the enabled OAuth service IPs list.
-- It first get out the day and time in the settings, and then,
-- if it's time to check it will check.
function check_ip_list_of_enabled_OAuth_services(enabled_OAuth_service_list)
	for i = 1, # enabled_OAuth_service_list do
		local uci = require "luci.model.uci".cursor()
		local check_enabled = uci:get("kikiauth", enabled_OAuth_service_list[i], "check_enabled")
		if check_enabled ~= nil then
			local day, time, search_pattern
			day = uci:get("kikiauth", enabled_OAuth_service_list[i], "day")
			time= uci:get("kikiauth", enabled_OAuth_service_list[i], "time")
			-- search_pattern is for 'time' checking. In this situation,
			-- we want to check if the current time and
			-- the one in the setting is different to each other within the range of 3 minutes.
			search_pattern = time .. ":0[012]"
			--check if the current day and time match the ones in the settings.
			if string.find(os.date(),day) ~= nil or day == "Every" and string.find(os.date(), search_pattern) ~= nil then
				 check_ips(enabled_OAuth_service_list[i])
			end
		end
    end
end

-- Check a particular service IPs list
-- @param service: "facebook" or "google" ...
function check_ips(service)
	local uci = luci.model.uci.cursor()
	local ips = uci:get_list("kikiauth", service, "ips")
	local sys = require "luci.sys"
	local newips = {}
	for _, ip in ipairs(ips) do
		local output = luci.sys.exec("ping -c 2 %s | grep '64 bytes' | awk '{print $1}'" % {ip})
		if output and output:find("64") then table.insert(newips, ip) end
	end
	uci:set_list("kikiauth", service, "ips", newips)
	uci:save("kikiauth")
	uci:commit("kikiauth")
end

function action_redirect_to_success_page()
	local uci = require "luci.model.uci".cursor()
	local success_url = uci:get("kikiauth","oauth_success_page","success_url")
	-- If the admin provides an URL, use it to redirect the client to. If not, redirect the client to his original request.
	if  success_url ~= nil then
		-- fix bug when the admin only enters a white-space string.
		-- In this case, we also redirect the client to his original request.
		if luci.util.trim(success_url) ~= "" then
			luci.http.redirect(success_url)
		else
			local success_text = uci:get("kikiauth", "oauth_success_page", "success_text")
			luci.http.write(success_text)
			--local sauth = require "luci.sauth"
			--local original_url = sauth.read("abc")
			--luci.http.redirect(original_url)
			--return
		end
	else
		local success_text = uci:get("kikiauth", "oauth_success_page", "success_text")
		luci.http.write(success_text)
		--local sauth = require "luci.sauth"
		--local original_url = sauth.read("abc")
		--luci.http.redirect(original_url)
	end
end

function action_auth_response_to_gw()
	local token = luci.http.formvalue("token")
	local url = nil
	local response = ''
	local actual_token = ''
	local domain = nil
	local resp = nil

	-- token will be like 'facebook_xxxxxxxxx' or 'google_xxxxxxx'
	-- or 'google_mbm.vn__xxxxxxx' (with Google Apps domain)
	if token:startswith('facebook_') then
		actual_token = token:sub(10)
		url = "https://graph.facebook.com/me?access_token=%s" % {actual_token}
	elseif token:startswith('google_') then
		local rest = token:sub(8)
		domain = rest:match('^([%-a-z0-9%.]+%.[a-z]+)__')
		if domain then
			actual_token = rest:sub(domain:len() + 3)
		else
			actual_token = rest
		end
		url = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=%s" % {actual_token}
	end

	if url then
		response = luci.util.exec("wget --no-check-certificate -qO- %s" % {url})
	end

	if not response or response == "" then
		luci.http.write("Auth: 6")
		return
	end

	if token:startswith('facebook_') and string.find(response, "id", 1) ~= nil then
		luci.http.write("Auth: 1")
		return
	end

	if token:startswith('google_') and belongto_googleapps_domain(response, domain) then
		luci.http.write("Auth: 1")
		return
	end

	luci.http.write("Auth: 6")
	return
end

-- Check if the logged in email belongs to a Google Apps domain
function belongto_googleapps_domain(response, domain)
	-- If domain is not given, accept
	if domain == nil then return true end

	-- Get the part behind 'www.'
	if domain:startswith('www.') then
		domain = domain:sub(5)
	end
	local resp = luci.json.decode(response)
	if not resp then return false end

	local email = resp.email
	local verified_email = resp.verified_email

	if not verified_email then return false end

	local d = email:sub(email:find('@') + 1)
	return (d == domain)
end

-- Get IP list for an OAuth service.
-- @param service "facebook" or "google"
function get_oauth_ip_list(service)
	local x = luci.model.uci.cursor()
	local lip = x:get_list('kikiauth', service, 'ips')
	return to_ip_list(lip)
end

function to_ip_list(mixlist)
	if mixlist == nil then
		return {}
	end

	local allip = {}
	-- Convert from hostname (www-slb-10-01-prn1.facebook.com)
	-- to IP.
	for n, ip in ipairs(mixlist) do
		-- Check if ip is a hostname
		if not ip:match('^%d+.%d+.%d+.%d+$') then
			allip = luci.util.combine(allip, hostname_to_ips(ip))
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

function iptables_kikiauth_chain_exist()
	return (iptables_kikiauth_chain_exist_in_table('nat')
	        and iptables_kikiauth_chain_exist_in_table('filter'))
end

function check_fb_ip2()
	local httpc = require "luci.httpclient"
	local uci = require "luci.model.uci".cursor()
	local ips = {}
	ips = uci:get_list("kikiauth", "facebook", "ips")
	for i = 1, #ips do
		-- the "if" is used to fix the bug of accessing a nil value of the "ips" table
		-- (because when one element is removed,
		-- the length of the ips table is correspondingly subtracted by 1).
		if ips[i] == nil then
			break
		end
		local res, code, msg = httpc.request_to_buffer("http://"..ips[i])
		print(code, msg)
		if code == -2 then
			table.remove(ips, i)
			-- we have to subtract "i" by 1 to keep track of the correct index of the 'ips' table
			-- that we want to loop in the next route because after removing an element,
			-- the next element will fill the removed position.
			i = i - 1
		end
	end
	for i=1,# ips do
		print(i, ips[i])
	end
end

function iptables_kikiauth_chain_exist_in_table(tname)
	local count = 0
	for line in luci.util.execi("iptables-save -t %s | grep %s" % {tname, chain}) do
		line = luci.util.trim(line)
		if count == 0 and line:startswith(":%s" % {chain}) then
			count = count + 1
		elseif count == 1 and line:endswith("-j %s" % {chain}) then
			count = count + 1
			break
		end
	end      -- If check OK, count == 2 now
	return (count > 1)
end

function iptables_kikiauth_create_chain()
	return (iptables_kikiauth_create_chain_in_table('nat')
	        and iptables_kikiauth_create_chain_in_table('filter'))
end

function iptables_kikiauth_create_chain_in_table(tname)
	local r = 0
	luci.sys.call("iptables -t %s -N %s" % {tname, chain})
	local rootchain = 'PREROUTING'
	if tname == 'filter' then rootchain = 'FORWARD' end
	r = r + luci.sys.call("iptables -t %s -A %s -j %s" % {tname, rootchain, chain})
	return (r == 0) -- Convert from zero (success) to true
end

-- Move the KikiAuth chain to suitable position between WifiDog chains
function iptables_kikiauth_insert_to_wifidog()
	-- Get the name of WifiDog's WiFi2Internet chain.
	-- WiFiDog_eth0_WIFI2Internet or similar
	local c = "iptables -t filter -S FORWARD | egrep -io 'WiFiDog_[a-z0-9]+_WIFI2Internet'"
	local wd_internet_chname = luci.util.trim(luci.util.exec(c))
	if wd_internet_chname == '' then
		return
	end
	-- Get the name of WiFiDog's AuthServers.
	-- WiFiDog_eth0_AuthServers or similar
	c = "iptables -t filter -S %s | egrep -io 'WiFiDog_[a-z0-9]+_AuthServers'" % {wd_internet_chname}
	local wd_authserver_chname = luci.util.trim(luci.util.exec(c))
	if wd_authserver_chname == '' then
		return
	end
	-- Determine the position of AuthServer rule in WiFi2Internet chain
	c = "iptables -t filter -S %s | grep -i '\\-A '" % {wd_internet_chname}
	local pos = 0
	for line in luci.util.execi(c) do
		pos = pos + 1
		if line:find(wd_authserver_chname) then break end
	end
	-- Insert KikiAuth rule right after
	c = "iptables -t filter -I %s %d -j %s" % {wd_internet_chname, pos+1, chain}
	luci.sys.call(c)
	-- Remove KikiAuth rule from FORWARD chain
	c = "iptables -t filter -D FORWARD -j %s" % {chain}
	luci.sys.call(c)
end

function iptables_kikiauth_remove_from_wifidog()
	local r = 0
	-- Get the name of WifiDog's WiFi2Internet chain.
	-- WiFiDog_eth0_WIFI2Internet or similar
	local c = "iptables -t filter -S FORWARD | egrep -io 'WiFiDog_[a-z0-9]+_WIFI2Internet'"
	local wd_internet_chname = luci.util.trim(luci.util.exec(c))
	if wd_internet_chname == '' then
		return
	end
	-- Delete KikiAuth rule from Wifidog
	while r == 0 do
		c = "iptables -t filter -D %s -j %s" % {wd_internet_chname, chain}
		r = luci.sys.call(c)
	end
	return (r == 0)
end

function iptables_kikiauth_delete_chain_from_table(tname)
	local r = 0
	luci.sys.call("iptables -t %s -F %s" % {tname, chain})
	local rootchain = 'PREROUTING'
	if tname == 'filter' then rootchain = 'FORWARD' end
	while r == 0 do
		r = luci.sys.call("iptables -t %s -D %s -j %s" % {tname, rootchain, chain})
	end
	luci.sys.call("iptables -t %s -X %s" % {tname, chain})
	luci.sys.call(c)
	return (not iptables_kikiauth_chain_exist())
end

function iptables_kikiauth_delete_chain()
	iptables_kikiauth_remove_from_wifidog()
	return (iptables_kikiauth_delete_chain_from_table('filter')
	        and iptables_kikiauth_delete_chain_from_table('nat'))
end

function iptables_kikiauth_add_iprule(address, excluded)
	local l
	if address:match('^%d+.%d+.%d+.%d+$') then
		l = {address}
	else
		l = hostname_to_ips(address)
	end
	-- Chain nil variable to {} to avoid exception at luci.util.contains
	if excluded == nil then excluded = {} end
	for _, ip in ipairs(l) do
		if not luci.util.contains(excluded, ip) then
			local c = "iptables -t nat -A %s -d %s -p tcp --dport 443 -j ACCEPT" % {chain, ip}
			luci.sys.call(c)
			local c = "iptables -t filter -A %s -d %s -p tcp --dport 443 -j ACCEPT" % {chain, ip}
			luci.sys.call(c)
		end
	end
end

function iptables_kikiauth_get_ip_list()
	local l = {}
	for line in luci.util.execi("iptables-save -t nat | grep '%s -d'" % {chain}) do
		table.insert(l, line:match('%-d (%d+.%d+.%d+.%d+)'))
	end
	return l
end

function iptables_kikiauth_delete_iprule(iplist)
	for _, ip in ipairs(iplist) do
		local c = "iptables -t nat -D %s -d %s -p tcp -m tcp --dport 443 -j ACCEPT" % {chain, ip}
		luci.sys.call(c)
		c = "iptables -t filter-D %s -d %s -p tcp -m tcp --dport 443 -j ACCEPT" % {chain, ip}
		luci.sys.call(c)
	end
	-- If there is no rule left, delete the chain
	local existing = iptables_kikiauth_get_ip_list()
	if existing == {} then
		iptables_kikiauth_delete_chain()
	end
end