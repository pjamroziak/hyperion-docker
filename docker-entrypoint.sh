#!/bin/sh
set -eu

validate_id() {
    case "$2" in
        ''|0*|*[!0-9]*)
            printf '%s must be a positive decimal ID without leading zeros.\n' "$1" >&2
            exit 64
            ;;
    esac
}

validate_id PUID "$PUID"
validate_id PGID "$PGID"

# Preserve device groups supplied through Docker without carrying over group 0.
supplementary_groups=
for gid in $(id -G); do
    if [ "$gid" != 0 ] && [ "$gid" != "$PGID" ]; then
        supplementary_groups="${supplementary_groups:+$supplementary_groups,}$gid"
    fi
done

groups_option=--clear-groups
if [ -n "$supplementary_groups" ]; then
    groups_option="--groups=$supplementary_groups"
fi

exec setpriv --reuid "$PUID" --regid "$PGID" "$groups_option" --no-new-privs \
    /bin/sh -c '
        if [ ! -w /config ] || [ ! -x /config ]; then
            printf "The /config directory must be writable and accessible by UID %s and GID %s.\n" "$PUID" "$PGID" >&2
            exit 1
        fi
        exec stdbuf -oL hyperiond --service --userdata /config "$@"
    ' hyperion "$@"
