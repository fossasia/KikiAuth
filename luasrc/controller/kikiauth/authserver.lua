module("luci.controller.kikiauth.authserver", package.seeall)

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