# shellcheck shell=sh
# Налаштування Samboryk OS мають пріоритет над стандартними налаштуваннями KDE.
case ":${XDG_CONFIG_DIRS:-}:" in
    *:/etc/xdg/samboryk:*) ;;
    *) XDG_CONFIG_DIRS="/etc/xdg/samboryk:${XDG_CONFIG_DIRS:-/etc/xdg}"; export XDG_CONFIG_DIRS ;;
esac
