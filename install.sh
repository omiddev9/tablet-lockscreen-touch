#!/usr/bin/env bash
# Omarchy Tablet Lockscreen Touch 1.0.1
#
# One installer for both on-screen keyboards a tablet needs on Omarchy:
#   1. boot / login screen  -> SDDM theme "tablet-lockscreen-touch"   (root part)
#   2. session lock screen  -> Quickshell lock plugin                 (user part)
#
# Both parts come from this one directory: nothing is fetched from the network,
# and nothing is installed as a separate package.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

THEME_ID=tablet-lockscreen-touch
THEME_DIR=${TABLET_LOCK_TOUCH_THEME_DIR:-/usr/share/sddm/themes}
THEME_PATH=$THEME_DIR/$THEME_ID
SDDM_CONF_DIR=${TABLET_LOCK_TOUCH_SDDM_CONF_DIR:-/etc/sddm.conf.d}
SDDM_DROPIN=$SDDM_CONF_DIR/zz-$THEME_ID-theme.conf

PLUGIN_ID=io.github.omiddev9.tablet-lockscreen-touch
PLUGINS_DIR=$HOME/.config/omarchy/plugins
PLUGIN_PATH=$PLUGINS_DIR/$PLUGIN_ID
SHELL_JSON=$HOME/.config/omarchy/shell.json
PLUGIN_FILES=(manifest.json Service.qml LockView.qml TouchKeyboard.qml)

stamp=$(date +%Y%m%d-%H%M%S)

log() { printf '  %s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# Everything that lands outside $HOME goes through as_root. TABLET_LOCK_TOUCH_NO_ROOT=1
# runs the same command unprivileged, which is how a packaging test drives it.
as_root() {
  if [ "${TABLET_LOCK_TOUCH_NO_ROOT:-0}" = 1 ] || [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

# ---------------------------------------------------------------- checks -----
[ -f "$here/sddm-theme/metadata.desktop" ] || die "sddm-theme/ is missing next to this script"
[ -f "$here/manifest.json" ] || die "manifest.json is missing next to this script"
[ -f "$here/Service.qml" ] || die "Service.qml is missing next to this script"
command -v python3 >/dev/null || die "python3 is required (used to edit shell.json safely)"
if [ "${TABLET_LOCK_TOUCH_NO_ROOT:-0}" != 1 ] && [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null || die "sudo is required to install the SDDM theme"
fi

# ------------------------------------------------- 1. boot/login keyboard -----
step "SDDM login theme -> $THEME_PATH"

as_root install -d -m 0755 "$THEME_DIR"
if [ -d "$THEME_PATH" ] && ! diff -rq "$here/sddm-theme" "$THEME_PATH" >/dev/null 2>&1; then
  as_root cp -a "$THEME_PATH" "$THEME_PATH.bak-$stamp"
  log "old theme saved to $THEME_PATH.bak-$stamp"
fi
as_root install -d -m 0755 "$THEME_PATH"
as_root cp -R "$here/sddm-theme/." "$THEME_PATH/"
# The greeter runs as the login UI and handles other users' passwords, so it must
# not stay owned or writable by the account that ran this installer: a process
# controlling that account could otherwise replace the greeter and capture the
# passwords typed into it afterwards.
if [ "${TABLET_LOCK_TOUCH_NO_ROOT:-0}" = 1 ]; then
  log "TABLET_LOCK_TOUCH_NO_ROOT=1: theme ownership left unchanged (test mode)"
else
  as_root chown -R 0:0 "$THEME_PATH"
  as_root chmod -R u=rwX,go=rX "$THEME_PATH"
  log "theme files in place (owner root, not writable by the installing user)"
fi

as_root install -d -m 0755 "$SDDM_CONF_DIR"
want_dropin=$'[Theme]\nCurrent='"$THEME_ID"
if [ -f "$SDDM_DROPIN" ] && [ "$(cat "$SDDM_DROPIN")" = "$want_dropin" ]; then
  log "$SDDM_DROPIN already selects $THEME_ID"
else
  if [ -f "$SDDM_DROPIN" ]; then
    as_root cp -a "$SDDM_DROPIN" "$SDDM_DROPIN.bak-$stamp"
    log "old drop-in saved to $SDDM_DROPIN.bak-$stamp"
  fi
  printf '[Theme]\nCurrent=%s\n' "$THEME_ID" | as_root tee "$SDDM_DROPIN" >/dev/null
  log "wrote $SDDM_DROPIN"
fi

# -------------------------------------------------- 2. session lock screen ----
step "Session lock (touch keypad) -> $PLUGIN_PATH"

# Installed by the plugin manager the checkout already *is* the plugin folder;
# copying a directory onto itself would fail, so leave those files alone.
if [ -d "$PLUGIN_PATH" ] && [ "$(cd "$here" && pwd -P)" = "$(cd "$PLUGIN_PATH" && pwd -P)" ]; then
  log "already in place (installed by the plugin manager); files left alone"
else
  install -d -m 0755 "$PLUGIN_PATH"
  cp -a "${PLUGIN_FILES[@]/#/$here/}" "$PLUGIN_PATH/"
  log "lock files in place"
fi

if [ -f "$SHELL_JSON" ]; then
  cp -a "$SHELL_JSON" "$SHELL_JSON.bak-$stamp"
  log "shell.json saved to $SHELL_JSON.bak-$stamp"
fi

python3 - "$SHELL_JSON" "$PLUGIN_ID" <<'PY'
import json, os, sys

path, plugin_id = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path) and os.path.getsize(path) > 0:
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)

plugins = data.get("plugins")
if not isinstance(plugins, list):
    plugins = []
    data["plugins"] = plugins

def entry_id(item):
    return item.get("id") if isinstance(item, dict) else item

if any(entry_id(item) == plugin_id for item in plugins):
    print("  shell.json already lists " + plugin_id)
else:
    plugins.append({"id": plugin_id})
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, ensure_ascii=False)
        handle.write("\n")
    print("  registered " + plugin_id + " in shell.json")

disabled = data.get("disabledPlugins") or []
if "omarchy.lock" not in disabled:
    print()
    print("  note: the stock lock is still enabled. Two lock services fight over")
    print("        the session, so run:  omarchy plugin disable omarchy.lock")
PY

if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell -q shell reloadConfig >/dev/null 2>&1 || true
  omarchy-shell -q shell rescanPlugins >/dev/null 2>&1 || true
  if omarchy-shell -q shell ping >/dev/null 2>&1; then
    log "asked the running shell to rescan plugins"
  else
    log "shell not running; the lock loads on next login"
  fi
fi

# ------------------------------------------------------------- 3. verify -----
step "Check"
[ -f "$THEME_PATH/Main.qml" ] && log "login theme:  $THEME_PATH/Main.qml"
[ -f "$THEME_PATH/Keypad.qml" ] && log "login keypad: $THEME_PATH/Keypad.qml"
[ -f "$PLUGIN_PATH/Service.qml" ] && log "lock service: $PLUGIN_PATH/Service.qml"
[ -f "$PLUGIN_PATH/TouchKeyboard.qml" ] && log "lock keypad:  $PLUGIN_PATH/TouchKeyboard.qml"

printf '\nDone. Both keyboards are installed from this one package.\n'
printf '  - login screen: restart SDDM (reboot, or: sudo systemctl restart sddm)\n'
printf '  - session lock: log out and back in, then lock the session to test\n'
printf 'Nothing else is installed: no extra packages, no shell commands are required.\n'
