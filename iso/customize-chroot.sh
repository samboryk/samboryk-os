#!/bin/bash
# Виконується всередині розпакованої системи Kubuntu під час збирання ISO.
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
export SAMBORYK_SKIP_INITRAMFS=1
LC_ALL=C.UTF-8; export LC_ALL

log() { printf '\033[1;35m  ->\033[0m %s\n' "$*"; }

# Ядро не оновлюємо: живий сеанс завантажує ядро з самого ISO,
# і модулі в системі мають йому відповідати.
kernel_pkgs() {
    { dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 'linux-image-*' 'linux-modules-*' \
        'linux-headers-*' 'linux-generic*' 2>/dev/null || true; } | awk '$1 == "ii" {print $2}'
}
kernel_pkgs | xargs -r apt-mark hold >/dev/null

log "32-бітна архітектура для Steam і Wine"
dpkg --add-architecture i386

log "Оновлюю списки пакетів"
apt-get update -q

# Steam питає згоду з ліцензією — відповідаємо наперед
echo "steam steam/question select I AGREE" | debconf-set-selections
echo "steam steam/license note ''" | debconf-set-selections

# Рекомендовані програми (Steam, Wine, KDE Connect…) ставимо явно: новий розв'язувач
# залежностей apt 3 пропускає рекомендації, якщо для них треба оновити вже
# встановлені бібліотеки.
log "Шукаю рекомендовані програми в архіві Ubuntu"
mapfile -t RECS < <(for d in /tmp/samboryk/samboryk-*.deb; do dpkg-deb -f "$d" Recommends; done \
    | tr ',' '\n' | sed -e 's/([^)]*)//g' -e 's/|.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | grep -v -e '^$' -e '^samboryk-' | sort -u)
EXTRA=()
for p in "${RECS[@]}"; do
    cand="$(apt-cache policy "$p" 2>/dev/null | sed -n 's/^[[:space:]]*Candidate:[[:space:]]*//p')"
    if [ -n "$cand" ] && [ "$cand" != "(none)" ]; then
        EXTRA+=("$p")
    else
        log "немає в архіві, пропускаю: $p"
    fi
done

log "Встановлюю пакети Samboryk OS і ${#EXTRA[@]} рекомендованих програм"
apt-get install -y -q /tmp/samboryk/samboryk-*.deb "${EXTRA[@]}"

for p in samboryk-branding samboryk-theme samboryk-icons samboryk-desktop; do
    dpkg -s "$p" >/dev/null 2>&1 || { echo "Не встановився $p" >&2; exit 1; }
done
log "Що з рекомендованого встановилося:"
for p in kdeconnect timeshift gamemode mangohud steam-installer lutris wine; do
    if dpkg -s "$p" >/dev/null 2>&1; then echo "     так  $p"; else echo "     ні   $p"; fi
done

# Стандартні налаштування Kubuntu в /etc/skel перекривали б тему Samboryk
mkdir -p /usr/share/samboryk/skel-backup
for f in kdeglobals kwinrc plasmarc ksplashrc kscreenlockerrc \
         plasma-org.kde.plasma.desktop-appletsrc plasmashellrc; do
    if [ -f "/etc/skel/.config/$f" ]; then
        log "Прибираю /etc/skel/.config/$f (копія в /usr/share/samboryk/skel-backup)"
        mv "/etc/skel/.config/$f" /usr/share/samboryk/skel-backup/
    fi
done

# Інсталятор Calamares: назва й логотип
B=/etc/calamares/branding/kubuntu
if [ -f "$B/branding.desc" ]; then
    log "Брендинг інсталятора"
    cp /tmp/samboryk/samboryk-logo-256.png "$B/samboryk-logo.png"
    sed -i \
        -e 's/^\(\s*productName:\s*\).*/\1"Samboryk OS"/' \
        -e 's/^\(\s*shortProductName:\s*\).*/\1"Samboryk OS"/' \
        -e "s/^\(\s*version:\s*\).*/\1\"$VERSION\"/" \
        -e "s/^\(\s*shortVersion:\s*\).*/\1\"$VERSION\"/" \
        -e "s/^\(\s*versionedName:\s*\).*/\1\"Samboryk OS $VERSION\"/" \
        -e "s/^\(\s*shortVersionedName:\s*\).*/\1\"Samboryk OS $VERSION\"/" \
        -e 's/^\(\s*productLogo:\s*\).*/\1"samboryk-logo.png"/' \
        -e 's/^\(\s*productIcon:\s*\).*/\1"samboryk-logo.png"/' \
        "$B/branding.desc"
fi

log "Прибираю за собою"
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/*.bin /tmp/* 2>/dev/null || true
kernel_pkgs | xargs -r apt-mark unhold >/dev/null
truncate -s 0 /etc/machine-id 2>/dev/null || true
