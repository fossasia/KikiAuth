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
local class = luci.util.class

SerFlag = class(Flag)
function SerFlag.write(self, section, value)
	if value == '1' then
		if not authserver.iptables_kikiauth_chain_exist() then
			authserver.iptables_kikiauth_create_chain()
		end
		-- We write the default value for "ips" option below.
		-- Due to a bug (?), this value is not written.
		if self.section.fields['ips'] then
			local default_ips = self.section.fields['ips'].default
			local ip_option = self.section.fields['ips']
			ip_option:write(section, default_ips)
		end
	end
	Flag.write(self, section, value)
end

function SerFlag.remove(self, section)
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


IPList = class(DynamicList)
function IPList.cfgvalue(self, section)
	return DynamicList.cfgvalue(self, section) or self.default
end

function IPList.write(self, section, value)
	-- There is a bug (?) from CBI, by which the default value is not sent to write.
	if authserver.iptables_kikiauth_chain_exist() then
		local added = authserver.iptables_kikiauth_get_ip_list()
		for _, address in ipairs(value) do
			authserver.iptables_kikiauth_add_iprule(address, added)
		end
		authserver.iptables_kikiauth_insert_to_wifidog()
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

s:tab("general", translate("General settings"))
s:tab("ip", translate("Service IP addresses"))

e = s:taboption("general", SerFlag, "enabled", translate("Enabled?"))

---***---
p = s:taboption("general", Value, "app_id", "App ID/ Client ID",
                translate("The App ID/API Key of your <a href='https://developers.facebook.com/apps'>\
                          registered Facebook app</a>."))
p:depends('enabled', '1')
p.default = '420756987974770'
p = s:taboption("general", Value, "redirect_uri", "Redirect URI",
             translate("This URI has to be match the one you registered for your Facebook app."))
p:depends('enabled', '1')
p.default = 'http://openwrt.lan/cgi-bin/luci/kikiauth/oauth/facebookcallback'

---***---
p = s:taboption("ip", IPList, "ips", "Facebook IPs",translate("List of Facebook IPs used for the gateway to open the traffic correctly while using Facebook OAuth."))
p:depends('enabled', '1')
p.default = {'www-slb-10-01-prn1.facebook.com',
             'www-slb-11-12-prn1.facebook.com',
             's-static.ak.fbcdn.net'}

---***---
p = s:taboption("ip", Flag, "check_enabled", translate("Periodically check and remove deprecated IP?"))
p:depends('enabled', '1')
p = s:taboption("ip", ListValue, "day", translate("Day"))
p:depends('check_enabled', '1')
local weekdays = {{'Sun', 'Sunday'},
                  {'Mon', 'Monday'},
                  {'Tue', 'Tuesday'},
                  {'Wed', 'Wednesday'},
                  {'Thu', 'Thursday'},
                  {'Fri', 'Friday'},
                  {'Sat', 'Saturday'},
                  {'Every', 'Everyday'}}
for _, d in ipairs(weekdays) do
	p:value(d[1], translate(d[2]))
end
p = s:option(ListValue, "time", translate("Time"))
p:depends('check_enabled', '1')
for i = 0, 23 do
	p:value("%02d" % {i}, tostring(i))
end

---***---
s = m:section(NamedSection, "google", "oauth_services", "Google",
              translate("You can register your own Google app and use its parameters here."))
s:tab("general", translate("General settings"))
s:tab("ip", translate("Service IP addresses"))

s:taboption("general", SerFlag, "enabled", translate("Enabled?"))

p = s:taboption("general", Flag, "googleall", translate("Accept all Google accounts?"),
                translate("User can use any Google Account email to login.<br/>"))
p:depends('enabled', '1')

p = s:taboption("general", DynamicList, "googleapps", translate("Accept these Google Apps domains"),
            translate("Ex. <i>mbm.vn</i>. User will login with <i>@mbm.vn</i> email.<br />\
                      <b>Note</b>: To limit to these domains, you have to uncheck the\
                      <i>all Google account</i> option above."))
p:depends('enabled', '1')

p = s:taboption("general", Value, "app_id", "App ID/ Client ID",
                translate("The Client ID of your app registered in\
                          <a href='https://code.google.com/apis/console/'>Google API Console</a>"))
p:depends('enabled', '1')
p.default = '242929894222-3909mjqkmgcdo9ro6mr91aiod083g834.apps.googleusercontent.com'

p = s:taboption("general", Value, "redirect_uri", "Redirect URI",
             translate("This URI has to be match the one you registered for your Google app.<br/>\
             Have to be HTTPS. Its domain/IP must be included in <i>Service IP addresses</i> list (next tab)."))
p:depends('enabled', '1')
p.default = 'https://kikiauth.appspot.com/google'

p = s:taboption("ip", IPList, "ips", "Google IPs",translate("List of Google IPs used for the gateway to open the traffic correctly while using Google OAuth."))
p:depends('enabled', '1')
p.default = {'accounts.l.google.com',
             'accounts-cctld.l.google.com',
             'clients.l.google.com',
             'googlehosted.l.googleusercontent.com',
             'ssl.gstatic.com',
             'kikiauth.appspot.com'}

p = s:taboption("ip", Flag, "check_enabled", translate("Periodically check and remove deprecated IP?"))
p:depends('enabled', '1')

p = s:taboption("ip", ListValue, "day", translate("Day"))
p:depends('check_enabled', '1')
for _, d in ipairs(weekdays) do
	p:value(d[1], translate(d[2]))
end

p = s:taboption("ip", ListValue, "time", translate("Time"))
p:depends('check_enabled', '1')
for i = 0, 23 do
	p:value("%02d" % {i}, tostring(i))
end


--[[
s = m:section(NamedSection, "twitter", "oauth_services", "Twitter")
s:option(Flag, "enabled", translate("Enabled?"))
p = s:option(Value, "app_id", "App ID/ Client ID")
p:depends('enabled', '1')
p = s:option(Value, "redirect_uri", "Redirect URI")
p:depends('enabled', '1')
--]]

s = m:section(NamedSection, "oauth_success_page", "success_page", "Success page",
              translate("You can set a default success page which users will be redirected to after logging in successfully. Or, you can just display some welcome text to these users; but notice that this text is only showed if you do not provide the 'Success URL' field a value."))
p = s:option(Value, "success_url", "Success URL")
p = s:option(TextValue, "success_text", "Success Text",translate("This is only displayed if you leave the 'Success URL' field blank. HTML tags can be used here."))
p.rows = 6

return m