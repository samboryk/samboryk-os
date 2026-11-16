#!/usr/bin/env bash
# Збирає .deb-пакети Samboryk OS з каталогу packages/.
#
# Змінні середовища:
#   CHANNEL   канал оновлень: alpha | beta | stable (типово alpha)
#   REPO_URL  адреса APT-репозиторію, напр. https://user.github.io/samboryk-os/apt
#   HOME_URL  сторінка проєкту, напр. https://github.com/user/samboryk-os
#   OUT       куди класти пакети (типово out/debs)
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
CHANNEL="${CHANNEL:-alpha}"
REPO_URL="${REPO_URL:-https://example.invalid/samboryk-os/apt}"
HOME_URL="${HOME_URL:-https://example.invalid/samboryk-os}"
OUT="${OUT:-$ROOT/out/debs}"
KEY="$ROOT/keys/samboryk-archive.asc"

# 0.1.0~alpha1 -> VERSION_ID=0.1, PRETTY_VERSION="0.1 Alpha 1"
VERSION_ID="$(echo "$VERSION" | cut -d. -f1,2)"
PRE="$(echo "$VERSION" | sed -n 's/^[^~]*~\([a-z]*\)\([0-9]*\)$/\1 \2/p')"
if [ -n "$PRE" ]; then
    PRETTY_VERSION="$VERSION_ID $(echo "$PRE" | sed 's/^\(.\)/\U\1/')"
else
    PRETTY_VERSION="$VERSION_ID"
fi

case "$CHANNEL" in alpha|beta|stable) ;; *) echo "Невідомий канал: $CHANNEL" >&2; exit 1 ;; esac

log() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$OUT"
rm -f "$OUT"/samboryk-*.deb

substitute() {
    # Підставляє @VERSION@ та інші змінні в усі текстові файли каталогу.
    local dir="$1"
    grep -rlI --null '@[A-Z_]*@' "$dir" 2>/dev/null | xargs -0 -r sed -i \
        -e "s|@VERSION@|$VERSION|g" \
        -e "s|@VERSION_ID@|$VERSION_ID|g" \
        -e "s|@PRETTY_VERSION@|$PRETTY_VERSION|g" \
        -e "s|@CHANNEL@|$CHANNEL|g" \
        -e "s|@REPO_URL@|$REPO_URL|g" \
        -e "s|@HOME_URL@|$HOME_URL|g"
}

fetch_icons() {
    local dest="$1"
    # shellcheck disable=SC1091
    . "$ROOT/packages/samboryk-icons/debian/upstream.conf"
    local src="$STAGE/whitesur-src"
    log "Завантажую значки WhiteSur ($ICONS_COMMIT)"
    git init -q "$src"
    git -C "$src" fetch -q --depth 1 "$ICONS_REPO" "$ICONS_COMMIT"
    git -C "$src" checkout -q FETCH_HEAD
    mkdir -p "$dest/usr/share/icons" "$dest/usr/share/doc/samboryk-icons"
    # -p замінює логотип Apple на логотип KDE
    (cd "$src" && bash ./install.sh -d "$dest/usr/share/icons" -p >/dev/null)
    cp "$src/COPYING" "$dest/usr/share/doc/samboryk-icons/copyright"
    # Кеш значків створюється на машині користувача в postinst
    find "$dest/usr/share/icons" -maxdepth 2 -name icon-theme.cache -delete
}

build_one() {
    local name="$1" src="$ROOT/packages/$1" pkg="$STAGE/$1"
    rm -rf "$pkg"
    mkdir -p "$pkg/DEBIAN"
    [ -d "$src/root" ] && cp -a "$src/root/." "$pkg/"

    case "$name" in
        samboryk-icons) fetch_icons "$pkg" ;;
        samboryk-archive-keyring)
            mkdir -p "$pkg/usr/share/keyrings"
            gpg --dearmor < "$KEY" > "$pkg/usr/share/keyrings/samboryk-archive-keyring.gpg" ;;
    esac

    for f in control preinst postinst prerm postrm; do
        [ -f "$src/debian/$f" ] && cp "$src/debian/$f" "$pkg/DEBIAN/$f"
    done
    substitute "$pkg"

    # Файли в /etc — конфігураційні: dpkg не затре зміни користувача
    if [ -d "$pkg/etc" ]; then
        (cd "$pkg" && find etc -type f | sed 's|^|/|' | sort) > "$pkg/DEBIAN/conffiles"
    fi

    local size
    size="$(du -sk --exclude=DEBIAN "$pkg" | cut -f1)"
    echo "Installed-Size: $size" >> "$pkg/DEBIAN/control"

    find "$pkg" -path "$pkg/DEBIAN" -prune -o -type d -exec chmod 0755 {} +
    find "$pkg" -path "$pkg/DEBIAN" -prune -o -type f -exec chmod 0644 {} +
    [ -d "$pkg/usr/bin" ] && chmod 0755 "$pkg"/usr/bin/*
    for f in preinst postinst prerm postrm; do
        [ -f "$pkg/DEBIAN/$f" ] && chmod 0755 "$pkg/DEBIAN/$f"
    done
    chmod 0644 "$pkg/DEBIAN/control"
    [ -f "$pkg/DEBIAN/conffiles" ] && chmod 0644 "$pkg/DEBIAN/conffiles"

    dpkg-deb --root-owner-group -Zxz --build "$pkg" "$OUT/${name}_${VERSION}_all.deb" >/dev/null
    log "Готово: ${name}_${VERSION}_all.deb ($(du -h "$OUT/${name}_${VERSION}_all.deb" | cut -f1))"
}

log "Samboryk OS $VERSION · канал $CHANNEL"
for dir in "$ROOT"/packages/*/; do
    name="$(basename "$dir")"
    if [ "$name" = samboryk-archive-keyring ] && [ ! -f "$KEY" ]; then
        log "Пропускаю $name: немає ключа keys/samboryk-archive.asc (оновлення через репозиторій будуть вимкнені)"
        continue
    fi
    build_one "$name"
done
