#!/usr/bin/env bash
# Оновлює APT-репозиторій Samboryk OS (його роздає GitHub Pages).
#
#   tools/build-repo.sh <каталог-сайту>
#
# Змінні: CHANNEL (alpha|beta|stable), DEBS (типово out/debs),
#         GPG_KEY_ID — яким ключем підписувати (обов'язково).
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="${1:?Вкажіть каталог сайту, напр. public}"
CHANNEL="${CHANNEL:-alpha}"
DEBS="${DEBS:-$ROOT/out/debs}"
: "${GPG_KEY_ID:?Задайте GPG_KEY_ID — ключ для підпису репозиторію}"

case "$CHANNEL" in alpha|beta|stable) ;; *) echo "Невідомий канал: $CHANNEL" >&2; exit 1 ;; esac
command -v apt-ftparchive >/dev/null || { echo "Потрібен apt-ftparchive (пакет apt-utils)" >&2; exit 1; }
ls "$DEBS"/*.deb >/dev/null 2>&1 || { echo "Немає пакетів у $DEBS — спершу tools/build-debs.sh" >&2; exit 1; }

APT="$SITE/apt"
POOL="pool/$CHANNEL"
DIST="dists/$CHANNEL"
mkdir -p "$APT/$POOL" "$APT/$DIST/main/binary-amd64"

# У каналі лишаємо тільки найсвіжішу версію кожного пакета
for deb in "$DEBS"/*.deb; do
    name="$(dpkg-deb -f "$deb" Package)"
    rm -f "$APT/$POOL/${name}"_*.deb
    cp "$deb" "$APT/$POOL/"
done

cd "$APT"
apt-ftparchive packages "$POOL" > "$DIST/main/binary-amd64/Packages"
gzip -9kf "$DIST/main/binary-amd64/Packages"

apt-ftparchive \
    -o APT::FTPArchive::Release::Origin="Samboryk OS" \
    -o APT::FTPArchive::Release::Label="Samboryk OS" \
    -o APT::FTPArchive::Release::Suite="$CHANNEL" \
    -o APT::FTPArchive::Release::Codename="$CHANNEL" \
    -o APT::FTPArchive::Release::Architectures="amd64" \
    -o APT::FTPArchive::Release::Components="main" \
    -o APT::FTPArchive::Release::Description="Samboryk OS updates ($CHANNEL)" \
    release "$DIST" > "$DIST/Release.tmp"
mv "$DIST/Release.tmp" "$DIST/Release"

rm -f "$DIST/InRelease" "$DIST/Release.gpg"
gpg --batch --yes --default-key "$GPG_KEY_ID" --clearsign -o "$DIST/InRelease" "$DIST/Release"
gpg --batch --yes --default-key "$GPG_KEY_ID" -abs -o "$DIST/Release.gpg" "$DIST/Release"
gpg --armor --export "$GPG_KEY_ID" > samboryk-archive.asc

touch "$SITE/.nojekyll"
echo "Репозиторій оновлено: канал $CHANNEL, пакетів: $(ls "$POOL"/*.deb | wc -l)"
