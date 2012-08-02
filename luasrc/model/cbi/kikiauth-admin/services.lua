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

s = m:section(NamedSection, "oauth2", "oauth_services", translate("OAuth v2.0 services"))
sv = s:option(MultiValue, "services", "Enabled")
sv:value("google", "Google");
sv:value("facebook", "Facebook")

s = m:section(NamedSection, "oauth1", "oauth_services", translate("OAuth v1.0 services"))
sv = s:option(MultiValue, "services", "Enabled")
sv:value("twitter", "Twitter")

return m