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

module("luci.controller.kikiauth.admin", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/kikiauth") then
		return
	end

	entry({"admin", "network", "kikiauth"}, cbi("kikiauth-admin/services"), "KikiAuth")
end
