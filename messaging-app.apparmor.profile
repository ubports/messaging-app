# vim:syntax=apparmor

#include <tunables/global>

# Specified profile variables
@{APP_ID_DBUS}="messaging_2dapp"
@{APP_PKGNAME_DBUS}="messaging_2dapp"
@{APP_PKGNAME}="com.ubuntu.messaging-app"

profile "messaging-app.ubports-app_1.0.0" (attach_disconnected) {
  network,
  / rwkl,
  /** rwlkm,
  /** pix,
  dbus,
  signal,
  ptrace,
  unix,
}
