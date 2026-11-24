#!/usr/bin/env bash
# Tablet Lockscreen Touch 1.0.0 — removes everything install.sh put in place.
set -euo pipefail

THEME_ID=tablet-lockscreen-touch
THEME_DIR=${TABLET_LOCK_TOUCH_THEME_DIR:-/usr/share/sddm/themes}
THEME_PATH=$THEME_DIR/$THEME_ID
SDDM_CONF_DIR=${TABLET_LOCK_TOUCH_SDDM_CONF_DIR:-/etc/sddm.conf.d}
SDDM_DROPIN=$SDDM_CONF_DIR/zz-$THEME_ID-theme.conf

PLUGIN_ID=io.github.omiddev9.tablet-lockscreen-touch
PLUGINS_DIR=$HOME/.config/omarchy/plugins
PLUGIN_PATH=$PLUGINS_DIR/$PLUGIN_ID
SHELL_JSON=$HOME/.config/omarchy/shell.json

stamp=$(date +%Y%m%d-%H%M%S)

log() { printf '  %s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }

as_root() {
  if [ "${TABLET_LOCK_TOUCH_NO_ROOT:-0}" = 1 ] || [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

step "Session lock"
if [ -d "$PLUGIN_PATH" ]; then
  rm -rf "$PLUGIN_PATH"
  log "removed $PLUGIN_PATH"
else
  log "not installed"
fi

if [ -f "$SHELL_JSON" ]; then
  cp -a "$SHELL_JSON" "$SHELL_JSON.bak-$stamp"
  python3 - "$SHELL_JSON" "$PLUGIN_ID" <<'PY'
import json, os, sys

path, plugin_id = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

plugins = data.get("plugins")
if isinstance(plugins, list):
    kept = [item for item in plugins
            if (item.get("id") if isinstance(item, dict) else item) != plugin_id]
    if len(kept) != len(plugins):
        data["plugins"] = kept
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(data, handle, indent=2, ensure_ascii=False)
            handle.write("\n")
        print("  unregistered " + plugin_id + " from shell.json")
    else:
        print("  shell.json had no " + plugin_id + " entry")
PY
fi

if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell -q shell reloadConfig >/dev/null 2>&1 || true
  omarchy-shell -q shell rescanPlugins >/dev/null 2>&1 || true
fi

step "SDDM login theme"
if [ -d "$THEME_PATH" ]; then
  as_root rm -rf "$THEME_PATH"
  log "removed $THEME_PATH"
else
  log "not installed"
fi
if [ -f "$SDDM_DROPIN" ]; then
  as_root rm -f "$SDDM_DROPIN"
  log "removed $SDDM_DROPIN"
fi

printf '\nDone. The stock Omarchy theme/lock are untouched — re-select them yourself:\n'
printf '  omarchy plugin enable omarchy.lock    # if you had disabled it\n'
printf '  sudo systemctl restart sddm           # to leave this login theme\n'
printf 'Backups from earlier runs are left behind on purpose (look for *.bak-*).\n'
