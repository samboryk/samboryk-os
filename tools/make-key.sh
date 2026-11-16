#!/usr/bin/env bash
# Створює ключ, яким підписуються оновлення Samboryk OS.
# Запускати один раз. На Windows підходить Git Bash (у ньому вже є gpg).
#
# Результат:
#   keys/samboryk-archive.asc            публічний ключ — комітиться в репозиторій
#   keys/PRIVATE-samboryk-archive.asc    приватний ключ — НЕ комітиться,
#                                        вставляється в секрет GitHub і видаляється
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUB="$ROOT/keys/samboryk-archive.asc"
PRIV="$ROOT/keys/PRIVATE-samboryk-archive.asc"

if [ -f "$PUB" ]; then
    echo "Ключ уже є: $PUB. Новий ключ зламає оновлення в уже встановлених системах." >&2
    exit 1
fi

export GNUPGHOME
GNUPGHOME="$(mktemp -d)"
trap 'rm -rf "$GNUPGHOME"' EXIT

gpg --batch --pinentry-mode loopback --passphrase '' \
    --quick-gen-key "Samboryk OS Archive <noreply@samboryk.invalid>" ed25519 sign never

mkdir -p "$ROOT/keys"
gpg --armor --export > "$PUB"
gpg --armor --export-secret-keys > "$PRIV"
chmod 600 "$PRIV"

echo
echo "Готово."
echo "1. Відкрийте $PRIV, скопіюйте весь текст і вставте його на GitHub:"
echo "   Settings → Secrets and variables → Actions → New repository secret,"
echo "   назва: SAMBORYK_GPG_PRIVATE_KEY"
echo "2. Після цього видаліть файл $PRIV."
echo "3. Закомітьте keys/samboryk-archive.asc."
