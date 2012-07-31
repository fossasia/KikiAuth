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
