KikiAuth
========

KikiAuth is based on LuCI, providing an alternative to Auth Server for WifiDog.
KikiAuth aims to support authentication via OAuth services (Google, Facebook, Twitter...) only and run on the same box as WifiDog (no need to setup a separated machine for authentication).

Build
-----
You must have a copy of LuCI source tree (luci-0.10).
Copy KikiAuth folder to luci-0.10/applications.
Run
    make runhttpd
to compile.

Build ipk package
-----
Copy the folder to openwrt/package (source tree)
Rename Makefile_build_standalone to Makefile (replace the old Makefile)
Choose the luci-app-kikiauth in"make menuconfig".
Run "make package/luci-app-kikiauth/compile V=99" to build.
