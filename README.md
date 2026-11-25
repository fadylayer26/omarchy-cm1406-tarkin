# Omarchy CM1406 — Tarkin Edition

> **NOT TESTED YET ON A REAL ASUS CM1406.** Prototype `0.3.0-dev`, prepared for first community testing. No claim is made that the installer, Omarchy package set, Mali GPU acceleration, audio, suspend, Wi-Fi or the graphical session has been validated on hardware.

## But

Créer un système Omarchy ARM64 sur une **clé USB externe** pour ASUS Chromebook CM1406 (`google,tarkin`, MediaTek MT8189), en conservant le noyau ChromeOS/Tarkin et le stockage interne eMMC. Le projet part de la base Arch Linux ARM CM1406 v1.60 et installe le runtime Omarchy depuis son dépôt officiel AArch64 `edge` signé.

Le système Omarchy ARM est encore un canal roulant (`edge`). Les versions de paquets peuvent changer entre deux téléchargements. Le portage Tarkin n'est pas certifié par Omarchy upstream.

## Matériel et prérequis

- ASUS Chromebook CM1406 / carte `google,tarkin` / AArch64.
- Clé USB **32 Go recommandés** (minimum pratique à tester : 16 Go, selon la place requise par les paquets). **Tout le contenu de la clé choisie sera effacé.**
- Connexion Internet pendant l'installation et le premier démarrage.
- Autorisation explicite du propriétaire de l'appareil ou du service informatique de l'établissement pour démarrer un OS externe et écrire sur une clé USB.
- Démarrage externe déjà autorisé/configuré par l'administrateur. Cet installateur ne modifie aucun paramètre `crossystem` et ne désactive aucune protection ChromeOS.

Si l'appareil est géré par l'établissement ou que l'autorisation manque, **ne lance pas l'installation**. Demande à l'administrateur de confirmer si le démarrage externe est autorisé. Si Developer Mode ou les drapeaux de démarrage nécessaires ne sont pas déjà configurés, l'installateur s'arrête sans les modifier.

## Installation (procédure de test — NOT TESTED YET)

1. Dans ChromeOS, télécharge `omarchy-cm1406-tarkin-0.3.0-dev.zip` dans **Downloads / Téléchargements**.
2. Ouvre le terminal ChromeOS (`Ctrl+Alt+T`), tape `shell`, puis extrais l'archive :

   ```bash
   cd /var/tmp
   bsdtar -xf ~/MyFiles/Downloads/omarchy-cm1406-tarkin-0.3.0-dev.zip
   ```

3. **Uniquement si le propriétaire / service informatique a autorisé ce démarrage externe**, ouvre VT2 (`Ctrl+Alt+Refresh`), connecte-toi selon la procédure administrateur, puis depuis le dossier extrait lance :

   ```bash
   cd /var/tmp/omarchy-cm1406-tarkin
   sudo bash install.sh
   ```

Le script doit demander une confirmation d'autorisation, vérifier en lecture seule que le démarrage USB est déjà autorisé, identifier les supports USB amovibles, puis demander de sélectionner la clé. Vérifie attentivement le modèle et la taille affichés. **N'autorise jamais l'effacement d'un support contenant des données à conserver.** Le programme refuse l'eMMC et le disque système ChromeOS.

Le système télécharge Arch Linux ARM, prépare la clé, installe le noyau ChromeOS/Tarkin signé pour la clé et installe les paquets Omarchy AArch64 signés. Au premier démarrage, il tente de préparer le pilote GPU Tarkin puis de finaliser l'utilisateur Omarchy. En cas d'échec de la session, le lanceur doit revenir au terminal Tarkin.

## Ce que cette version tente d'intégrer

- Base Arch Linux ARM du dépôt CM1406 v1.60.
- Noyau vendor ChromeOS et modules correspondants, sans installer de noyau Omarchy/Limine.
- Profil matériel Tarkin (pas les Device Trees/configurations `quigon` du Lenovo).
- Runtime Omarchy et ses réglages depuis le dépôt AArch64 `edge`, signatures de paquets requises. Le script choisit Chromium ARM64 si disponible, sinon Firefox, pour fournir l'identifiant de navigateur attendu par le finaliseur Omarchy.
- Configuration Hyprland/UWSM/Quickshell. La session UWSM appelle le lanceur `hyprland-mali` fourni par le socle CM1406 afin de conserver son environnement EGL/Mali; l’appel direct de Hyprland est volontairement évité.
- Adaptation au service graphique Tarkin existant : aucun second gestionnaire d'affichage n'est ajouté.
- Initialisation du compte `alarm` via `omarchy-provision-user --first-install`, avec une liste de scripts utilisateur restreinte pour éviter les réglages matériels ASUS/Qualcomm/Dell génériques.

Les paquets `sddm`, `networkmanager`, `docker`, `snapper`, `limine` et les noyaux Omarchy ne sont pas activés ou utilisés pour le démarrage. Le réseau du socle reste basé sur systemd-networkd / wpa_supplicant. Certaines dépendances du paquet Omarchy peuvent néanmoins être installées sans que leurs services soient activés.

## Reprise et dépannage

- Si le téléchargement ou l'installation est interrompu, garde la même clé connectée et relance `sudo bash install.sh` depuis le même dossier. Le lanceur peut proposer de reprendre les étapes enregistrées.
- Journal de l'installation : `/var/tmp/tarkin-install.log`.
- Journal de premier démarrage : `/var/log/tarkin-firstboot.log`.
- Diagnostic Tarkin/Omarchy (lecture seule, sur le système démarré) : `bash omarchy/scripts/omarchy-preflight.sh` depuis le dossier du projet, ou les outils Tarkin présents sur la clé.
- Si l'Omarchy GUI ne démarre pas, l'adaptateur essaie de revenir au terminal Tarkin. Conserve les journaux avant de refaire une installation.

## Limites connues — à tester

- **Aucune installation ou session graphique n'a été testée sur un vrai CM1406 avec cette archive.**
- Le dépôt Omarchy `edge` est roulant : une dépendance AArch64 peut disparaître ou changer de nom/version.
- Tous les logiciels optionnels du manifeste Omarchy ne sont pas nécessairement publiés pour AArch64. Le script les signale et ignore ceux absents au lieu de compiler silencieusement depuis l'AUR. Cette intégration n'exécute volontairement pas `omarchy-apply-system` ni les scripts matériels génériques.
- La cohabitation UWSM / seatd / `tarkin-console.service` et le passage du lanceur `hyprland-mali` à UWSM sont expérimentaux.
- Le fonctionnement du Wi-Fi, Bluetooth, son, caméra, touchpad, écran tactile, luminosité, veille, accélération Mali et Quickshell doit être testé séparément.
- Le premier démarrage a besoin d'un réseau actif et de suffisamment d'espace libre.
- Si le dépôt ARM `edge` ne fournit pas les paquets requis, l'étape Omarchy échouera et le journal donnera le paquet en cause. Ne remplace pas les paquets par des binaires x86_64.

## Sécurité / périmètre

- Le script refuse les disques internes et n'écrit que sur un disque USB externe explicitement choisi.
- Il ne change pas `crossystem`, ne désactive pas Verified Boot, ne modifie pas le firmware, TPM/GSC, ni les partitions eMMC.
- Il vérifie que la configuration de démarrage USB requise est **déjà** en place. Si elle ne l'est pas, contacte le propriétaire / service IT ; n'utilise pas de contournement.
- L'installation détruit les données de la clé USB ciblée.
- Le Chromebook fourni par un établissement ne doit être modifié qu'avec son autorisation.

## Sources et licences

- Base CM1406 : https://github.com/codebutnotnerd/boot-arch-linux-on-CM1406-asus-without-using-ssh
- Référence Omarchy/Lenovo : https://github.com/zoan37/lenovo-slim3-chromebook-omarchy
- Runtime Omarchy : https://github.com/omacom/omarchy
- Paquets Omarchy : https://github.com/omacom/omarchy-pkgs
- Guide Omarchy ARM / dépôt `edge` : https://github.com/omacom/omarchy/discussions/15702

Respecter `LICENSE`, `base/cm1406-arch/LICENSE` et `references/LENOVO-OMARCHY-LICENSE`, ainsi que les licences des composants tiers. Le runtime Omarchy et les firmwares propriétaires ne sont pas redistribués dans cette archive.
