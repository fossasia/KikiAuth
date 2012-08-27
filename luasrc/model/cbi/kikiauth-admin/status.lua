authserver = require "luci.controller.kikiauth.authserver"
local class      = luci.util.class

ApButton = class(Button)
function ApButton.set_state(self, st)
	if st == "apply" then
		self.inputtitle = translate("Apply")
		self.inputstyle = 'apply'
	else
		self.inputtitle = translate("Remove")
		self.inputstyle = 'remove'
	end
end


f = SimpleForm("status", translate("Status"))
f.reset = false
f.submit = false
s = f:section(SimpleSection)

o = s:option(ApButton, "open_access",
         translate("Open access to OAuth services (default is blocked by WifiDog)"))

if authserver.iptables_kikiauth_chain_exist() then
	o:set_state("remove")
else
	o:set_state("apply")
end
-- Functions for the button
function o.write(self, section)
	if self.inputstyle == 'apply' then
		-- Create iptables chain
		authserver.iptables_kikiauth_delete_chain()
		local r = authserver.iptables_kikiauth_create_chain()
		-- Get IPs to add to iptables chain
		local services = authserver.get_enabled_OAuth_service_list()
		local ips = {}
		for _, serv in ipairs(services) do
			local combine = luci.util.combine(ips, authserver.get_oauth_ip_list(serv))
			-- Avoid to use nil table.
			if combine ~= nil then ips = combine end
		end
		-- Add rule to iptables
		for _, ip in ipairs(ips) do
			authserver.iptables_kikiauth_add_iprule(ip)
		end
		if r then self:set_state('remove') end
	else
		if authserver.iptables_kikiauth_delete_chain() then self:set_state('apply') end
	end
end

return f