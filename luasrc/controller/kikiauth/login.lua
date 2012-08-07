module("luci.controller.kikiauth.login", package.seeall)

function index()
	entry({"kikiauth", "login"}, call("show_login_form"), "Login", 10).dependent = false
	entry({"kikiauth", "ping"}, call("pingpong"), "", 10).dependent = false
end

function show_login_form()
	luci.http.prepare_content("text/plain")
	luci.http.write("Login")
end

function pingpong()
	luci.http.prepare_content("text/plain")
	luci.http.write("Pong")
end
