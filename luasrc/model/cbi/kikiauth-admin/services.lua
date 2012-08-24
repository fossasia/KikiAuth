--[[
Admin page for KikiAuth - the replacement for WifiDog's auth server,
to provide OAuth support.

Copyright 2012 Nguyen Hong Quan <ng.hong.quan@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--
authserver = require "luci.controller.kikiauth.authserver"
local class      = luci.util.class

IPList = class(DynamicList)
function IPList.write(self, section, value)
	if authserver.iptables_kikiauth_chain_exist() then
		local added = authserver.iptables_kikiauth_get_ip_list()
		for _, address in ipairs(value) do
			authserver.iptables_kikiauth_add_iprule(address, added)
		end
	end
	DynamicList.write(self, section, value)
end
function IPList.remove(self, section)
	-- Get only old IPs of this section. Don't touch other's.
	local old_own_ips = self.map:get(section, self.option)
	old_own_ips = authserver.to_ip_list(old_own_ips)
	authserver.iptables_kikiauth_delete_iprule(old_own_ips)
	DynamicList.remove(self, section)
end

m = Map("kikiauth", "KikiAuth", translate("KikiAuth creates a captive portal to work with WifiDog. KikiAuth support logging in with popular OAuth services account.")) -- We want to edit the uci config file /etc/config/kikiauth

s = m:section(NamedSection, "facebook", "oauth_services", "Facebook",
              translate("You can register your own Facebook app and use its parameters here."))
e = s:option(Flag, "enabled", translate("Enabled?"))

function e.write(self, section, value)
	if value == '1' then
		if not authserver.iptables_kikiauth_chain_exist() then
			authserver.iptables_kikiauth_create_chain()
		end
	end
	Flag.write(self, section, value)
end

function e.remove(self, section)
	--[[
	local dd = os.date('%H:%M:%S')
	local l = "%s remove %s" % {dd, section}
	luci.sys.call("echo '%s' >> /tmp/log_kikiauth.txt" % {l})
	--]]

	-- Delete iptables rules for IPs belonging to this service.
	local old_own_ips = self.map:get(section, "ips")
	old_own_ips = authserver.to_ip_list(old_own_ips)
	authserver.iptables_kikiauth_delete_iprule(old_own_ips)
	Flag.remove(self, section)
end


---***---
p = s:option(Value, "app_id", "App ID/ Client ID")
p:depends('enabled', '1')
p.default = '420756987974770'
p = s:option(Value, "redirect_uri", "Redirect URI",
             translate("This URI has to be match the one you registered for your Facebook app."))
p:depends('enabled', '1')
p.default = 'http://openwrt.lan/cgi-bin/luci/kikiauth/oauth/facebookcallback'

---***---
p = s:option(IPList, "ips", "Facebook IPs",translate("List of Facebook IPs used for the gateway to open the traffic correctly while using Facebook OAuth."))
p:depends('enabled', '1')

---***---
p = s:option(Flag, "check_enabled", translate("Periodically check the Facebook IPs list?"))
p:depends('enabled', '1')
p = s:option(ListValue, "day", translate("Day"))
p:depends('check_enabled', '1')
p:value("Sun", translate("Sunday"))
p:value("Mon", translate("Monday"))
p:value("Tue", translate("Tuesday"))
p:value("Wed", translate("Wednesday"))
p:value("Thu", translate("Thursday"))
p:value("Fri", translate("Friday"))
p:value("Sat", translate("Saturday"))
p:value("Every", translate("Everyday"))
p = s:option(ListValue, "time", translate("Time"))
p:depends('check_enabled', '1')
p:value("00", translate("0"))
p:value("01", translate("1"))
p:value("02", translate("2"))
p:value("03", translate("3"))
p:value("04", translate("4"))
p:value("05", translate("5"))
p:value("06", translate("6"))
p:value("07", translate("7"))
p:value("08", translate("8"))
p:value("09", translate("9"))
p:value("10", translate("10"))
p:value("11", translate("11"))
p:value("12", translate("12"))
p:value("13", translate("13"))
p:value("14", translate("14"))
p:value("15", translate("15"))
p:value("16", translate("16"))
p:value("17", translate("17"))
p:value("18", translate("18"))
p:value("19", translate("19"))
p:value("20", translate("20"))
p:value("21", translate("21"))
p:value("22", translate("22"))
p:value("23", translate("23"))

---***---
s = m:section(NamedSection, "google", "oauth_services", "Google",
              translate("You can register your own Google app and use its parameters here."))
s:option(Flag, "enabled", translate("Enabled?"))
p = s:option(Value, "app_id", "App ID/ Client ID")
p:depends('enabled', '1')
p.default = '396818136722.apps.googleusercontent.com'
p = s:option(Value, "redirect_uri", "Redirect URI",
             translate("This URI has to be match the one you registered for your Google app."))
p:depends('enabled', '1')
p = s:option(IPList, "ips", "Google IPs",translate("List of Google IPs used for the gateway to open the traffic correctly while using Google OAuth."))
p:depends('enabled', '1')
p = s:option(Flag, "check_enabled", translate("Periodically check the Google IPs list?"))
p:depends('enabled', '1')
p = s:option(ListValue, "day", translate("Day"))
p:depends('check_enabled', '1')
p:value("Sun", translate("Sunday"))
p:value("Mon", translate("Monday"))
p:value("Tue", translate("Tuesday"))
p:value("Wed", translate("Wednesday"))
p:value("Thu", translate("Thursday"))
p:value("Fri", translate("Friday"))
p:value("Sat", translate("Saturday"))
p:value("Every", translate("Everyday"))
p = s:option(ListValue, "time", translate("Time"))
p:depends('check_enabled', '1')
p:value("00", translate("0"))
p:value("01", translate("1"))
p:value("02", translate("2"))
p:value("03", translate("3"))
p:value("04", translate("4"))
p:value("05", translate("5"))
p:value("06", translate("6"))
p:value("07", translate("7"))
p:value("08", translate("8"))
p:value("09", translate("9"))
p:value("10", translate("10"))
p:value("11", translate("11"))
p:value("12", translate("12"))
p:value("13", translate("13"))
p:value("14", translate("14"))
p:value("15", translate("15"))
p:value("16", translate("16"))
p:value("17", translate("17"))
p:value("18", translate("18"))
p:value("19", translate("19"))
p:value("20", translate("20"))
p:value("21", translate("21"))
p:value("22", translate("22"))
p:value("23", translate("23"))

--[[
s = m:section(NamedSection, "twitter", "oauth_services", "Twitter")
s:option(Flag, "enabled", translate("Enabled?"))
p = s:option(Value, "app_id", "App ID/ Client ID")
p:depends('enabled', '1')
p = s:option(Value, "redirect_uri", "Redirect URI")
p:depends('enabled', '1')
--]]

return m