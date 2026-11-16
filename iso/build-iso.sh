#!/usr/bin/env bash
# Збирає ISO Samboryk OS: бере офіційний образ Kubuntu 26.04 LTS,
# розпаковує систему, ставить пакети Samboryk і пакує назад.
#
#   sudo -E iso/build-iso.sh
#
# Змінні середовища:
#   BASE_ISO    шлях до вже завантаженого образу Kubuntu (необов'язково)
#   BASE_URL    каталог на cdimage.ubuntu.com (типово — шукається сам)
#   DEBS        каталог із пакетами Samboryk (типово out/debs)
#   WORK        робочий каталог, потрібно ~30 ГБ (типово work/)
#   OUT         куди класти ISO (типово out/)
#   CHANNEL     канал оновлень (alpha | beta | stable)
#   SQUASHFS_COMP  стискання системи: xz (типово, найменший образ) або zstd/lz4 (швидше)
#   MIN_FREE_GB    скільки місця вимагати перед стартом (типово 28)
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
CHANNEL="${CHANNEL:-alpha}"
DEBS="${DEBS:-$ROOT/out/debs}"
WORK="${WORK:-$ROOT/work}"
OUT="${OUT:-$ROOT/out}"
ISO_NAME="samboryk-os-${VERSION//\~/-}-amd64.iso"
SQUASHFS_COMP="${SQUASHFS_COMP:-xz}"
MIN_FREE_GB="${MIN_FREE_GB:-28}"

log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mПомилка:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "запустіть через sudo -E"
for t in xorriso unsquashfs mksquashfs curl sha256sum chroot; do
    command -v "$t" >/dev/null || die "немає програми $t (sudo apt install xorriso squashfs-tools curl)"
done
ls "$DEBS"/samboryk-*.deb >/dev/null 2>&1 || die "немає пакетів у $DEBS — спершу tools/build-debs.sh"

mkdir -p "$WORK" "$OUT"
avail_kb="$(df -Pk "$WORK" | awk 'NR==2 {print $4}')"
[ "$avail_kb" -gt $((MIN_FREE_GB * 1024 * 1024)) ] || die "у $WORK замало місця: потрібно ~$MIN_FREE_GB ГБ, вільно $((avail_kb / 1024 / 1024)) ГБ"

# ---------------------------------------------------------------- 1. Образ Kubuntu
if [ -z "${BASE_ISO:-}" ]; then
    if [ -z "${BASE_URL:-}" ]; then
        for v in 26.04.3 26.04.2 26.04.1 26.04; do
            u="https://cdimage.ubuntu.com/kubuntu/releases/$v/release"
            if curl -fsIL "$u/kubuntu-$v-desktop-amd64.iso" >/dev/null 2>&1; then
                BASE_URL="$u"; BASE_VER="$v"; break
            fi
        done
        [ -n "${BASE_URL:-}" ] || die "не знайшов образ Kubuntu 26.04 на cdimage.ubuntu.com; задайте BASE_URL або BASE_ISO"
    fi
    BASE_VER="${BASE_VER:-$(basename "$(dirname "$BASE_URL")")}"
    BASE_ISO="$WORK/kubuntu-$BASE_VER-desktop-amd64.iso"
    if [ ! -f "$BASE_ISO" ]; then
        log "Завантажую Kubuntu $BASE_VER"
        curl -fL --retry 3 -o "$BASE_ISO.part" "$BASE_URL/kubuntu-$BASE_VER-desktop-amd64.iso"
        mv "$BASE_ISO.part" "$BASE_ISO"
    fi
    log "Перевіряю контрольну суму"
    curl -fsSL "$BASE_URL/SHA256SUMS" -o "$WORK/SHA256SUMS"
    (cd "$WORK" && grep " \*\?$(basename "$BASE_ISO")\$" SHA256SUMS | sed 's/ \*/  /' | sha256sum -c -) \
        || die "контрольна сума образу не збігається"
fi
[ -f "$BASE_ISO" ] || die "немає образу $BASE_ISO"

# ---------------------------------------------------------------- 2. Розпаковка
EX="$WORK/iso"
FS="$WORK/rootfs"
cleanup() {
    for m in run sys proc dev/pts dev; do
        mountpoint -q "$FS/$m" 2>/dev/null && umount -lf "$FS/$m" || true
    done
}
trap cleanup EXIT

rm -rf "$EX" "$FS"
mkdir -p "$EX"
log "Розпаковую образ"
xorriso -osirrox on -indev "$BASE_ISO" \
    -extract /casper "$EX/casper" \
    -extract /boot/grub "$EX/grub" \
    -extract /md5sum.txt "$EX/md5sum.txt" 2>/dev/null || true
[ -d "$EX/casper" ] || die "в образі немає каталогу /casper"

if [ ! -f "$EX/casper/filesystem.squashfs" ]; then
    ls "$EX/casper"
    die "образ має багатошарову файлову систему; цей скрипт розрахований на Kubuntu з одним filesystem.squashfs"
fi

log "Розпаковую файлову систему (кілька хвилин)"
unsquashfs -q -d "$FS" "$EX/casper/filesystem.squashfs"

# ---------------------------------------------------------------- 3. Налаштування в chroot
log "Готую chroot"
mount --bind /dev "$FS/dev"
mount --bind /dev/pts "$FS/dev/pts"
mount -t proc proc "$FS/proc"
mount -t sysfs sys "$FS/sys"
mount -t tmpfs tmpfs "$FS/run"

if [ -e "$FS/etc/resolv.conf" ] || [ -L "$FS/etc/resolv.conf" ]; then
    mv "$FS/etc/resolv.conf" "$FS/etc/resolv.conf.samboryk-orig"
fi
cp -L /etc/resolv.conf "$FS/etc/resolv.conf"
printf '#!/bin/sh\nexit 101\n' > "$FS/usr/sbin/policy-rc.d"
chmod 755 "$FS/usr/sbin/policy-rc.d"

mkdir -p "$FS/tmp/samboryk"
cp "$DEBS"/samboryk-*.deb "$FS/tmp/samboryk/"
cp "$ROOT/iso/customize-chroot.sh" "$FS/tmp/samboryk/"
cp "$ROOT/assets/samboryk-logo-256.png" "$FS/tmp/samboryk/"

log "Встановлюю Samboryk OS у систему"
chroot "$FS" env CHANNEL="$CHANNEL" VERSION="$VERSION" /bin/bash /tmp/samboryk/customize-chroot.sh

rm -rf "$FS/tmp/samboryk" "$FS/usr/sbin/policy-rc.d"
rm -f "$FS/etc/resolv.conf"
if [ -e "$FS/etc/resolv.conf.samboryk-orig" ] || [ -L "$FS/etc/resolv.conf.samboryk-orig" ]; then
    mv "$FS/etc/resolv.conf.samboryk-orig" "$FS/etc/resolv.conf"
fi
cleanup

# ---------------------------------------------------------------- 4. Пакування
log "Оновлюю маніфест"
chroot "$FS" dpkg-query -W --showformat='${Package}\t${Version}\n' > "$EX/casper/filesystem.manifest"
du -sx --block-size=1 "$FS" | cut -f1 > "$EX/casper/filesystem.size"

log "Пакую файлову систему (це найдовший крок)"
rm -f "$EX/casper/filesystem.squashfs"
mksquashfs "$FS" "$EX/casper/filesystem.squashfs" -comp "$SQUASHFS_COMP" -b 1M -noappend -quiet
rm -rf "$FS"

# Назва в меню завантаження
for cfg in "$EX/grub/grub.cfg" "$EX/grub/loopback.cfg"; do
    [ -f "$cfg" ] && sed -i '/menuentry/ s/Kubuntu/Samboryk OS/g' "$cfg"
done

mkdir -p "$EX/.disk"
echo "Samboryk OS $VERSION \"Graphite\" - amd64 ($(date -u +%Y%m%d))" > "$EX/.disk/info"

# Контрольні суми змінених файлів
if [ -f "$EX/md5sum.txt" ]; then
    for f in casper/filesystem.squashfs casper/filesystem.size casper/filesystem.manifest \
             boot/grub/grub.cfg boot/grub/loopback.cfg .disk/info; do
        local_path="$EX/$f"
        case "$f" in boot/grub/*) local_path="$EX/grub/$(basename "$f")" ;; esac
        [ -f "$local_path" ] || continue
        sum="$(md5sum "$local_path" | cut -d' ' -f1)"
        if grep -q "  \./$f\$" "$EX/md5sum.txt"; then
            sed -i "s|^[0-9a-f]*  \./$f\$|$sum  ./$f|" "$EX/md5sum.txt"
        else
            echo "$sum  ./$f" >> "$EX/md5sum.txt"
        fi
    done
fi

log "Збираю ISO"
MAP=(-map "$EX/casper/filesystem.squashfs" /casper/filesystem.squashfs
     -map "$EX/casper/filesystem.size" /casper/filesystem.size
     -map "$EX/casper/filesystem.manifest" /casper/filesystem.manifest
     -map "$EX/.disk/info" /.disk/info)
[ -f "$EX/grub/grub.cfg" ] && MAP+=(-map "$EX/grub/grub.cfg" /boot/grub/grub.cfg)
[ -f "$EX/grub/loopback.cfg" ] && MAP+=(-map "$EX/grub/loopback.cfg" /boot/grub/loopback.cfg)
[ -f "$EX/md5sum.txt" ] && MAP+=(-map "$EX/md5sum.txt" /md5sum.txt)

rm -f "$OUT/$ISO_NAME"
xorriso -indev "$BASE_ISO" -outdev "$OUT/$ISO_NAME" \
    "${MAP[@]}" \
    -boot_image any replay \
    -padding included

(cd "$OUT" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256")
log "Готово: $OUT/$ISO_NAME ($(du -h "$OUT/$ISO_NAME" | cut -f1))"
