KikiAuth
========

KikiAuth is based on LuCI, providing an alternative to Auth Server for WifiDog.
KikiAuth aims to support authentication via OAuth services (Google, Facebook, Twitter...) only and run on the same box as WifiDog (no need to setup a separated machine for authentication).

Important note
--------------

The project is halted, because of these obstacles:

- Entire Facebook website is on HTTPS. It means that if we let user to login to Facebook, we have to open all traffic to Facebook website. It means that even before logging in our splash screen, user still can use Facebook, Google. These sites are open to allow OAuth login.

- The firewall open the traffic based on destination IP address, not domain. It means that we have to find all IP addresses of facebook.com and other Facebook owned domains. But due to Facebook's load balancing mechanism, each time we query, the DNS returns a different set of IP addresses. The set of IP address also become invalid after a while, and come back valid after another time.

- Facebook doesn't use only facebook.com. It also uses various domains for other resource (JS, CSS). These are also not fixed and can be changed any time.

I can only have workaround for the second issue, by making the router to periodically retrieve new IP addresses for a set of known domain. But still, the overall is not reliable.

Build
-----

You must have a copy of LuCI source tree (luci-0.10).
Copy KikiAuth folder to luci-0.10/applications.

Run

    make runhttpd

to compile.

Build ipk package
-----

- Copy the folder to openwrt/package (source tree)
- Rename Makefile_build_standalone to Makefile (replace the old Makefile)
- Rename "dist" folder to "root"
- Choose the luci-app-kikiauth in `make menuconfig`.
- Run `make package/luci-app-kikiauth/compile V=99` to build.
