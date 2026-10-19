#!/usr/bin/env bash
# Fedora XFCE / Intel i915 diagnostic script
# Run this from a clean TTY (Ctrl+Alt+F3).
# It only COLLECTS diagnostic information; it does not modify system configuration.

OUT="$HOME/xfce-gpu-diagnostic-$(date +%Y%m%d-%H%M%S).txt"

exec > >(tee "$OUT") 2>&1

echo "============================================================"
echo " Fedora XFCE / Intel GPU Diagnostic Report"
echo " Date: $(date)"
echo " Host: $(hostname)"
echo "============================================================"
echo

echo "### 1. KERNEL / OS ###"
uname -a
echo
cat /etc/fedora-release 2>/dev/null || true
echo

echo "### 2. CURRENT SESSION ENVIRONMENT ###"
echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-<empty>}"
echo "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-<empty>}"
echo "DISPLAY=${DISPLAY:-<empty>}"
echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<empty>}"
echo
loginctl list-sessions 2>/dev/null || true
echo

echo "### 3. GRAPHICAL PROCESSES ###"
ps -eo user,pid,comm,args | grep -E \
'gnome-shell|xfwm4|xfce4-session|xfdesktop|xfce4-panel|labwc|wayfire|Xorg|Xwayland' \
| grep -v grep || true
echo

echo "### 4. GRAPHICS HARDWARE / DRIVER ###"
lspci -nnk -s 00:02.0
echo
lspci -nnk | grep -A4 -Ei 'VGA|3D|Display'
echo

echo "### 5. INXI GRAPHICS ###"
if command -v inxi >/dev/null 2>&1; then
    inxi -Gxx
else
    echo "inxi is not installed"
fi
echo

echo "### 6. i915 MODULE ###"
modinfo i915 2>/dev/null | grep -E '^(filename|version|firmware|description|parm):' || true
echo

echo "### 7. MESA / OPENGL PACKAGES ###"
rpm -qa | grep -Ei 'mesa|crocus|libglvnd|wayland|xorg-x11-server' | sort
echo

echo "### 8. GPU / i915 KERNEL LOGS (CURRENT BOOT) ###"
sudo journalctl -k -b --no-pager \
| grep -Ei 'i915|drm|gpu hang|gpu reset|resetting chip|context reset|crocus' \
| tail -100
echo

echo "### 9. ALL CURRENT-BOOT KERNEL ERRORS RELATED TO GRAPHICS ###"
sudo journalctl -k -b --no-pager \
| grep -Ei 'error|fail|hang|reset' \
| grep -Ei 'i915|drm|gpu|graphics|crocus' \
| tail -100
echo

echo "### 10. DISPLAY CONNECTORS / MODES ###"
if command -v xrandr >/dev/null 2>&1; then
    xrandr --verbose 2>/dev/null || echo "xrandr could not access the graphical display"
else
    echo "xrandr is not installed"
fi
echo

echo "### 11. PCI DEVICE DETAILS ###"
sudo lspci -vv -s 00:02.0
echo

echo "### 12. WIFI STATUS (DO NOT MODIFY) ###"
nmcli device status 2>/dev/null || true
echo
nmcli radio all 2>/dev/null || true
echo

echo "### 13. WIFI HARDWARE / DRIVER ###"
lspci -nnk -s 02:00.0 2>/dev/null || true
echo
sudo journalctl -k -b --no-pager \
| grep -Ei 'iwlwifi|wlp2s0|firmware' \
| tail -60
echo

echo "### 14. FIREWALL STATUS ###"
rpm -q firewalld 2>/dev/null || true
systemctl is-active firewalld 2>/dev/null || true
echo

echo "### 15. DNF CONSISTENCY ###"
sudo dnf check
echo

echo "============================================================"
echo "END OF REPORT"
echo "Saved to: $OUT"
echo "============================================================"
