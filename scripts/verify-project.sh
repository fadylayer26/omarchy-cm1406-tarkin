#!/usr/bin/env bash
# Vérifications locales non destructives du dépôt Omarchy CM1406/Tarkin.
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
export PYTHONDONTWRITEBYTECODE=1

printf '\n== Tests d’intégrité du portage ==\n'
python3 -m unittest discover -s tests -v

printf '\n== Tests amont CM1406 ==\n'
python3 -m unittest discover -s base/cm1406-arch/tests -v

printf '\n== Analyse syntaxique Bash ==\n'
while IFS= read -r -d '' file; do
  bash -n "$file" || { printf 'Syntaxe Bash invalide : %s\n' "$file" >&2; exit 1; }
done < <(find . -type f \( -name '*.sh' -o -path '*/usr/local/libexec/tarkin/omarchy-session' \) -print0)
printf 'Syntaxe Bash : OK\n'

if command -v shellcheck >/dev/null 2>&1; then
  printf '\n== ShellCheck ==\n'
  shellcheck omarchy/scripts/omarchy-preflight.sh \
    omarchy/rootfs-overlay/usr/local/libexec/tarkin/omarchy-session \
    scripts/verify-project.sh
else
  printf '\nShellCheck : non installé (contrôle ignoré)\n'
fi

printf '\nVérifications terminées. Aucun installateur, firmware ou périphérique bloc n’a été modifié.\n'
