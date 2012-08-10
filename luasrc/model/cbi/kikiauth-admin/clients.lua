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

s = m:section(NamedSection, "keepalive", "clients", translate("Keep-alive clients"),
              translate("List of IP addresses from which the connection to Internet is always allowed, \
              without having to log in."))
o = s:option(DynamicList, "ip")


return m