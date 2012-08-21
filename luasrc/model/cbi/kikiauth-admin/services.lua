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
m = Map("kikiauth", "KikiAuth", translate("KikiAuth creates a captive portal to work with WifiDog. KikiAuth support logging in with popular OAuth services account.")) -- We want to edit the uci config file /etc/config/kikiauth

s = m:section(NamedSection, "facebook", "oauth_services", "Facebook",
              translate("You can register your own Facebook app and use its parameters here."))
s:option(Flag, "enabled", translate("Enabled?"))
p = s:option(Value, "app_id", "App ID/ Client ID")
p:depends('enabled', '1')
p.default = '420756987974770'
p = s:option(Value, "redirect_uri", "Redirect URI",
             translate("This URI has to be match the one you registered for your Facebook app."))
p:depends('enabled', '1')
p.default = 'http://openwrt.lan/cgi-bin/luci/kikiauth/oauth/facebookcallback'

p = s:option(DynamicList, "ips", "Facebook IPs",translate("List of Facebook IPs used for the gateway to open the traffic correctly while using Facebook OAuth."))
p:depends('enabled', '1')

s = m:section(NamedSection, "google", "oauth_services", "Google",
              translate("You can register your own Google app and use its parameters here."))
s:option(Flag, "enabled", translate("Enabled?"))
p = s:option(Value, "app_id", "App ID/ Client ID")
p:depends('enabled', '1')
p.default = '396818136722.apps.googleusercontent.com'
p = s:option(Value, "redirect_uri", "Redirect URI",
             translate("This URI has to be match the one you registered for your Google app."))
p:depends('enabled', '1')

s = m:section(NamedSection, "twitter", "oauth_services", "Twitter")
s:option(Flag, "enabled", translate("Enabled?"))
p = s:option(Value, "app_id", "App ID/ Client ID")
p:depends('enabled', '1')
p = s:option(Value, "redirect_uri", "Redirect URI")
p:depends('enabled', '1')

return m