#!/bin/sh

get_updates() {
    CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/swayde-arch"
    CACHE_FILE="$CACHE_DIR/pacman-updates"
    if [ -f "$CACHE_FILE" ] && [ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -lt 30 ]; then
        cat "$CACHE_FILE"
    else
        if ! command -v checkupdates >/dev/null 2>&1; then
            echo "checkupdates was not found; install pacman-contrib to enable update status" >&2
            return 127
        fi

        mkdir -p "$CACHE_DIR" || return
        tmp_file=$(mktemp "$CACHE_DIR/pacman-updates.XXXXXX") || return
        if checkupdates > "$tmp_file"; then
            mv "$tmp_file" "$CACHE_FILE" || {
                status=$?
                rm -f "$tmp_file"
                return "$status"
            }
            cat "$CACHE_FILE"
        else
            status=$?
            rm -f "$tmp_file"
            return "$status"
        fi
    fi
}

case $1'' in
'status')
    UPDATES=$(get_updates) || exit $?
    COUNT=$(echo "$UPDATES" | grep -v '^$' | wc -l)
    TOOLTIP=$(echo "$UPDATES" | awk 1 ORS='\\n' | sed 's/\\n$//')
    jq -cn --arg count "$COUNT" --arg tooltip "$TOOLTIP" '{"text": $count, "tooltip": $tooltip}'
    ;;
'check')
    UPDATES=$(get_updates) || exit $?
    [ $(echo "$UPDATES" | grep -v '^$' | wc -l) -gt 0 ]
    exit $?
    ;;
'upgrade')
    if [ -x "$(command -v pacseek)" ]; then
        xdg-terminal-exec pacseek -u
    elif [ -x "$(command -v topgrade)" ]; then
        xdg-terminal-exec topgrade
    else
        xdg-terminal-exec pacman -Syu
    fi
    ;;
esac
