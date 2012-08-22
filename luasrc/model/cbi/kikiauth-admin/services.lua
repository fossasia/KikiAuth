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

p = s:option(Flag, "check_enabled", translate("Periodically check the Facebook IPs list?")) 
p:depends('enabled', '1')

p = s:option(ListValue, "day", translate("Day"))
p:depends('check_enabled', '1')
p:value(1, translate("Sunday"))
p:value(2, translate("Monday"))
p:value(3, translate("Tuesday"))  
p:value(4, translate("Wednesday"))  
p:value(5, translate("Thursday"))  
p:value(6, translate("Friday"))  
p:value(7, translate("Saturday"))  
p:value(8, translate("Everyday"))  

p = s:option(ListValue, "time", translate("Time"))
p:depends('check_enabled', '1')
p:value(1, translate("1"))
p:value(2, translate("2"))
p:value(3, translate("3"))
p:value(4, translate("4"))
p:value(5, translate("5"))
p:value(6, translate("6"))
p:value(7, translate("7"))
p:value(8, translate("8"))
p:value(9, translate("9"))
p:value(10, translate("10"))
p:value(11, translate("11"))
p:value(12, translate("12"))
p:value(13, translate("13"))
p:value(14, translate("14"))
p:value(15, translate("15"))
p:value(16, translate("16"))
p:value(17, translate("17"))
p:value(18, translate("18"))
p:value(19, translate("19"))
p:value(20, translate("20"))
p:value(21, translate("21"))
p:value(22, translate("22"))
p:value(23, translate("23"))
p:value(24, translate("24"))


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