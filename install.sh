#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
GO="$ROOT/base/cm1406-arch/install/go.sh"

fail() { printf '[ERREUR] %s\n' "$*" >&2; exit 1; }
[[ -x "$GO" ]] || fail "Le lanceur CM1406 est absent : $GO"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  exec bash "$GO" "$@"
fi

[[ $EUID -eq 0 ]] || fail "Lance ce script depuis VT2 avec sudo : sudo bash install.sh"

cat <<'NOTICE'
============================================================
 OMARCHY CM1406 — TARKIN EDITION 0.3.0-dev
============================================================
Ce programme prépare un système Omarchy expérimental sur une
clé USB EXTERNE. Le contenu de cette clé sera entièrement effacé.

Le Chromebook est-il autorisé par son propriétaire / service IT
à démarrer un système externe et à utiliser ce projet ?

Ce programme ne modifie PAS les paramètres ChromeOS, le firmware,
le TPM/GSC ni le stockage eMMC interne. Si le démarrage USB n'est
pas déjà autorisé par l'administrateur, il s'arrêtera.

Tape exactement : J'AI L'AUTORISATION
NOTICE

read -r -p '> ' answer
[[ "$answer" == "J'AI L'AUTORISATION" ]] || fail "Confirmation absente. Aucun périphérique n'a été modifié."

export TARKIN_WM="${TARKIN_WM:-omarchy}"
exec bash "$GO" "$@"
