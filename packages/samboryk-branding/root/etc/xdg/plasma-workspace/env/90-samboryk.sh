# shellcheck shell=sh
# Запускається під час старту Plasma: тримає /etc/xdg/samboryk першим у списку.
case ":${XDG_CONFIG_DIRS:-}:" in
    *:/etc/xdg/samboryk:*) ;;
    *) XDG_CONFIG_DIRS="/etc/xdg/samboryk:${XDG_CONFIG_DIRS:-/etc/xdg}"; export XDG_CONFIG_DIRS ;;
esac
