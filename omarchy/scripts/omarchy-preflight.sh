#!/usr/bin/env bash
# Diagnostic Tarkin/Omarchy en lecture seule. N'installe rien et ne modifie rien.
set -Eeuo pipefail

status=0
say() { printf '%-36s %s\n' "$1" "$2"; }
pass() { say "$1" "OK — $2"; }
warn() { say "$1" "À vérifier — $2"; status=1; }
fail() { say "$1" "ABSENT/INCOMPATIBLE — $2"; status=1; }

printf 'Omarchy CM1406 / Tarkin — diagnostic en lecture seule\n'
printf 'Date : %s\n' "$(date -Is 2>/dev/null || date)"
printf 'Hôte : %s\n\n' "$(hostname 2>/dev/null || printf unknown)"

arch="$(uname -m 2>/dev/null || printf unknown)"
if [[ "$arch" == aarch64 ]]; then pass "Architecture" "$arch"; else fail "Architecture" "attendu aarch64, détecté $arch"; fi

compatible="unavailable"
if [[ -r /proc/device-tree/compatible ]]; then
  compatible="$(tr '\0' ' ' </proc/device-tree/compatible 2>/dev/null | xargs || true)"
fi
if [[ "$compatible" == *google,tarkin* ]]; then pass "Device Tree" "$compatible"; else fail "Device Tree" "google,tarkin non détecté ($compatible)"; fi
if [[ "$compatible" == *mediatek,mt8189* ]]; then pass "SoC" "mediatek,mt8189"; else warn "SoC" "mediatek,mt8189 non détecté explicitement"; fi

if [[ -f /etc/arch-release ]] && command -v pacman >/dev/null 2>&1; then
  pass "Base Linux" "Arch Linux ARM / pacman présent"
else
  warn "Base Linux" "Arch Linux ARM ou pacman non détecté"
fi

if [[ -d /usr/share/omarchy ]]; then
  pass "Runtime Omarchy" "/usr/share/omarchy présent"
else
  warn "Runtime Omarchy" "absent — le programme d’installation doit le récupérer depuis le dépôt signé AArch64 edge"
fi
for cmd in uwsm Hyprland; do
  if command -v "$cmd" >/dev/null 2>&1; then pass "Commande $cmd" "présente"; else warn "Commande $cmd" "absente"; fi
done
if command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1; then pass "Quickshell" "présent"; else warn "Quickshell" "absent"; fi

if [[ -S "/run/user/$(id -u)/bus" ]]; then
  pass "D-Bus utilisateur" "socket présent"
else
  warn "D-Bus utilisateur" "socket non présent dans la session courante"
fi
if systemctl is-active --quiet seatd.service 2>/dev/null; then
  pass "seatd" "service actif"
else
  warn "seatd" "service inactif ou systemd inaccessible"
fi
if systemctl is-active --quiet tarkin-console.service 2>/dev/null; then
  pass "Propriétaire de l'écran" "tarkin-console.service actif"
  say "Intégration prévue" "remplacer son ExecStart, ne pas démarrer un second compositeur"
else
  warn "Propriétaire de l'écran" "tarkin-console.service inactif/non détecté"
fi

cards=()
for sys_card in /sys/class/drm/card[0-9]*; do
  [[ -e "$sys_card/device/driver" ]] || continue
  driver="$(readlink -f "$sys_card/device/driver" 2>/dev/null || true)"
  [[ "$driver" == *mediatek* ]] || continue
  card_name="$(basename "$sys_card")"
  [[ -e "/dev/dri/$card_name" ]] && cards+=("/dev/dri/$card_name")
done
case ${#cards[@]} in
  1) pass "DRM MediaTek" "${cards[0]}" ;;
  0) warn "DRM MediaTek" "aucune carte MediaTek trouvée via sysfs" ;;
  *) warn "DRM MediaTek" "plusieurs cartes détectées : ${cards[*]}" ;;
esac

if [[ -e /dev/mali0 ]]; then
  pass "Mali KBase" "/dev/mali0 présent"
else
  warn "Mali KBase" "/dev/mali0 absent (à comparer avec la pile GPU réellement utilisée)"
fi

printf "\nCe diagnostic ne modifie rien. Il ne valide ni le démarrage USB, ni l’accélération GPU, ni la session Omarchy.\n"
exit "$status"
