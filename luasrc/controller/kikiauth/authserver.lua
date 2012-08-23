module("luci.controller.kikiauth.authserver", package.seeall)

function index()
    entry({"kikiauth", "ping"}, call("action_say_pong"), "Click here", 10).dependent=false
    entry({"kikiauth", "auth"}, call("action_auth_response_to_gw"), "", 20).dependent=false
    entry({"kikiauth", "portal"}, call("action_redirect_to_success_page"), "Success page", 30).dependent=false
    entry({"kikiauth", "login"}, template("kikiauth/login"), "Login page", 40).dependent=false
    entry({"kikiauth", "oauth", "googlecallback"}, template("kikiauth/googlecallback"), "", 50).dependent=false
    entry({"kikiauth", "oauth", "facebookcallback"}, template("kikiauth/facebookcallback"), "", 60).dependent=false
    entry({"kikiauth", "check_ip"}, call("check_fb_ip"), "", 70).dependent=false
    entry({"kikiauth", "check_ip2"}, call("check_fb_ip2"), "", 80).dependent=false
end

function action_say_pong()
    luci.http.prepare_content("text/plain")
    luci.http.write("Pong")
    -- the following code is for checking the Facebook IPs list.
    -- It first get out the day and time in the settings, and then,
    -- if it's time to check it will check.
    local uci = require "luci.model.uci".cursor()
    local day, time, search_pattern                                                                          
    day = uci:get("kikiauth", "facebook", "day")                                
    time= uci:get("kikiauth", "facebook", "time")                               
    -- search_pattern is for 'time' checking. In this situation, 
    -- we want to check if the current time and 
    -- the one in the setting is different to each other within the range of 3 minutes.
    search_pattern = time..":0[012]"
    local sys = require "luci.sys"
    --check if the current day and time match the ones in the settings.
    if string.find(os.date(),day) ~= nil or day == "Every" 
            and string.find(os.date(), search_pattern) ~= nil then
        check_fb_ip()
    end
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
function check_fb_ip2()
    local httpc = require "luci.httpclient"
    local uci = require "luci.model.uci".cursor()                               
    local ips = {}
    ips = uci:get_list("kikiauth","facebook","ips")
    for i=1,# ips do
        -- the "if" is used to fix the bug of accessing a nil value of the "ips" table
        -- (because when one element is removed, 
        -- the length of the ips table is correspondingly subtracted by 1).
    	if ips[i] == nil then
    	    break
    	end
        local res, code, msg = httpc.request_to_buffer("http://"..ips[i])
        print(code, msg)
        if code == -2 then
            table.remove(ips,i)
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

function check_fb_ip()
    local uci = require "luci.model.uci".cursor()
    local ips = {}
    ips = uci:get_list("kikiauth","facebook","ips")
    local sys = require "luci.sys"
    for i=1,# ips do
        -- the "if" is used to fix the bug of accessing a nil value of the "ips" table       
        -- (because when one element is removed,                                             
        -- the length of the ips table is correspondingly subtracted by 1).
      	if ips[i] == nil then
      	    break
      	end
	local output = sys.exec("ping -c 2 "..ips[i].." | grep '64 bytes' | awk '{print $1}'")
	if string.find(output,"64") == nil then
	    table.remove(ips, i)
	    -- we have to subtract "i" by 1 to keep track of the correct index of the 'ips' t
            -- that we want to loop in the next route because after removing an element,     
            -- the next element will fill the removed position.  
	    i = i - 1
	end
    end
    uci:set_list("kikiauth","facebook","ips",ips)
    uci:save("kikiauth")
    uci:commit("kikiauth")
end
