#!/bin/bash
# ===========================================================================
#  Lumetools v1.0.0 - macOS launcher
#  Place in the game root (next to bin/), then double-click.
#  First run creates the CrossOver bottle and sets everything up.
# ===========================================================================
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
BIN="$ROOT/bin"
BOTTLE="Lumetools"
CX="/Applications/CrossOver.app/Contents/SharedSupport/CrossOver"
BDIR="$HOME/Library/Application Support/CrossOver/Bottles/$BOTTLE"
LOG="$BIN/mac-run.log"

die() {
    echo
    echo "  [x] $1"
    echo
    read -r -p "  Press Enter to exit..." _
    exit 1
}

echo
echo "  ==============================================="
echo "   Lumetools v1.0.0"
echo "  ==============================================="
echo

# --- environment check -----------------------------------------------------
[ -d "$BIN" ]                     || die "bin/ not found. Put this file in the game root (next to bin/)."
[ -f "$BIN/chusanApp.exe" ]       || die "bin/chusanApp.exe not found"
[ -f "$BIN/amdaemon.exe" ]        || die "bin/amdaemon.exe not found"
[ -d "$CX" ]                      || die "CrossOver not installed (https://www.codeweavers.com/crossover)"
[ -f "$BIN/inject_x64.exe" ]      || die "bin/inject_x64.exe not found - the toolset is missing"
[ -f "$BIN/Lumetools.ini" ]       || die "bin/Lumetools.ini not found - extract the overlay first"
echo "  [ok] environment check passed"

# --- 1. bottle (created on first run) --------------------------------------
if [ ! -d "$BDIR" ]; then
    echo "  [..] first run, creating the bottle (~1 min)..."
    "$CX/bin/cxbottle" --bottle "$BOTTLE" --create --template win10_64 \
        --description "Lumetools" >/dev/null 2>&1
    [ -d "$BDIR" ] || die "bottle creation failed"
    echo "  [ok] bottle created"
else
    echo "  [ok] bottle present"
fi

export CX_BOTTLE="$BOTTLE"
WINE="$CX/bin/wine"

# --- 2. 64-bit runtime -----------------------------------------------------
# The copies shipped with the game are 32-bit; amdaemon.exe is 64-bit
# and aborts on them (missing ??3@YAXPEAXHPEBDH@Z).
S32="$BDIR/drive_c/windows/system32"
if [ -f "$BIN/msvcr110.dll" ]; then
    cp -f "$BIN/msvcr110.dll" "$S32/msvcr110.dll"
    cp -f "$BIN/msvcp110.dll" "$S32/msvcp110.dll"
    echo "  [ok] 64-bit runtime installed"
fi

# --- 3. registry: pin native -----------------------------------------------
if [ -f "$BIN/fix-dll.reg" ]; then
    "$WINE" reg add "HKCU\\Software\\Wine\\DllOverrides" /v msvcr110 /t REG_SZ /d native /f >/dev/null 2>&1
    "$WINE" reg add "HKCU\\Software\\Wine\\DllOverrides" /v msvcp110 /t REG_SZ /d native /f >/dev/null 2>&1
    echo "  [ok] DLL overrides set"
fi

# --- 4. drives -------------------------------------------------------------
mkdir -p "$HOME/Lumetools/Y/SDHD"
ln -sfn "$HOME/Lumetools/Y" "$BDIR/dosdevices/y:" 2>/dev/null
if [ -d "$BIN/option" ]; then
    mkdir -p "$BDIR/drive_c/mount"
    rm -rf "$BDIR/drive_c/mount/Option"
    ln -sfn "$BIN/option" "$BDIR/drive_c/mount/Option"
fi
echo "  [ok] drives mounted"

# --- 5. config: create only when missing, never overwrite ---------------
LEGACY="sega""tools.ini"
if [ ! -f "$BIN/Lumetools.ini" ] && [ -f "$BIN/$LEGACY" ]; then
    cp "$BIN/$LEGACY" "$BIN/Lumetools.ini"
    echo "  [ok] migrated existing config to Lumetools.ini"
fi

if ! grep -qE "^default=.+" "$BIN/Lumetools.ini" 2>/dev/null; then
    echo
    echo "  [!] Lumetools.ini: [dns] default is empty"
    echo "      Open bin/Lumetools.ini and fill in server address + keychip"
    echo
    read -r -p "  Press Enter to exit..." _
    exit 1
fi
echo "  [ok] config present"

# --- 6. kill leftovers -----------------------------------------------------
pkill -9 -f "chusanApp.exe" 2>/dev/null
pkill -9 -f "amdaemon.exe"  2>/dev/null
pkill -9 -f "inject_x"      2>/dev/null
"$CX/bin/wineserver" -k >/dev/null 2>&1
sleep 2

# --- 7. launch -------------------------------------------------------------
: > "$LOG"
echo "=== $(date) ===" >> "$LOG"

cleanup() {
    "$WINE" taskkill /f /im amdaemon.exe >>"$LOG" 2>&1
    "$WINE" taskkill /f /im chusanApp.exe  >>"$LOG" 2>&1
    "$CX/bin/wineserver" -k >>"$LOG" 2>&1
}
trap cleanup EXIT INT TERM

cd "$BIN" || die "cannot enter $BIN"

echo "  [..] starting amdaemon ..."
"$WINE" inject_x64.exe -d -k chusanamhook.dll amdaemon.exe -f \
    -c config_common.json config_server.json config_client.json \
       config_cvt.json config_sp.json config_hook.json >>"$LOG" 2>&1 &
sleep 8

echo "  [..] starting the game ..."
if [ -f duolinguo.dll ]; then
    "$WINE" inject_x86.exe -d -k chusanhook.dll -k duolinguo.dll chusanApp.exe >>"$LOG" 2>&1
else
    "$WINE" inject_x86.exe -d -k chusanhook.dll chusanApp.exe >>"$LOG" 2>&1
fi

echo
echo "  Game exited. Log: bin/mac-run.log"
read -r -p "  Press Enter to close..." _
