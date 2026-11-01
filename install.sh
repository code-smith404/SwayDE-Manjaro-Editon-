#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage: ./install.sh [--dry-run] [--yes] [--root DIR]

Install the files in arch/files into the matching paths under the target root.
Existing files are moved to var/backups/swayde-arch before replacement.

Options:
  --dry-run   List payload entries and existing-path conflicts without changes.
  --yes       Skip the confirmation prompt.
  --root DIR  Install under DIR instead of / (useful for testing or image builds).
  -h, --help  Show this help.
EOF
}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
PAYLOAD="$SCRIPT_DIR/arch/files"
ROOT_DIR=/
DRY_RUN=false
ASSUME_YES=false

while (($#)); do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        --yes)
            ASSUME_YES=true
            ;;
        --root)
            if (($# < 2)) || [[ -z "$2" ]]; then
                echo "error: --root requires a directory" >&2
                exit 2
            fi
            ROOT_DIR=$2
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "error: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [[ ! -d "$PAYLOAD" ]]; then
    echo "error: install payload not found: $PAYLOAD" >&2
    exit 1
fi

if [[ "$ROOT_DIR" != /* ]]; then
    ROOT_DIR="$PWD/$ROOT_DIR"
fi
ROOT_DIR=$(realpath -m -- "$ROOT_DIR")

if [[ "$ROOT_DIR" == / ]] && ((EUID != 0)) && [[ "$DRY_RUN" == false ]]; then
    echo "error: installation into / requires root; run with sudo" >&2
    exit 1
fi

mapfile -d '' -t entries < <(find "$PAYLOAD" -mindepth 1 -print0 | sort -z)
if ((${#entries[@]} == 0)); then
    echo "error: install payload is empty: $PAYLOAD" >&2
    exit 1
fi

backup_root="$ROOT_DIR/var/backups/swayde-arch"
backup_dir=
conflicts=0

for source in "${entries[@]}"; do
    relative=${source#"$PAYLOAD"/}
    destination="$ROOT_DIR/$relative"
    needs_backup=false

    if [[ -e "$destination" || -L "$destination" ]]; then
        if [[ ! -d "$source" || -L "$source" || ! -d "$destination" || -L "$destination" ]]; then
            needs_backup=true
            ((conflicts += 1))
        fi
    fi

    if [[ "$needs_backup" == true ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            printf 'backup existing: /%s\n' "$relative"
        fi
    fi
    if [[ "$DRY_RUN" == true ]]; then
        if [[ -d "$source" && ! -L "$source" ]]; then
            printf 'create directory: /%s\n' "$relative"
        else
            printf 'install: /%s\n' "$relative"
        fi
    fi
done

printf 'Payload entries: %d; existing paths to back up: %d\n' \
    "${#entries[@]}" "$conflicts"

if [[ "$DRY_RUN" == true ]]; then
    exit 0
fi

if [[ "$ASSUME_YES" == false ]]; then
    read -r -p "Install these files under $ROOT_DIR? [y/N] " answer
    case "$answer" in
        y|Y|yes|YES)
            ;;
        *)
            echo "Installation cancelled."
            exit 0
            ;;
    esac
fi

mkdir -p -- "$ROOT_DIR"
ROOT_DIR=$(cd -- "$ROOT_DIR" && pwd -P)

for source in "${entries[@]}"; do
    relative=${source#"$PAYLOAD"/}
    destination="$ROOT_DIR/$relative"

    if [[ -d "$source" && ! -L "$source" ]]; then
        if [[ -e "$destination" || -L "$destination" ]]; then
            if [[ ! -d "$destination" || -L "$destination" ]]; then
                if [[ -z "$backup_dir" ]]; then
                    mkdir -p -- "$backup_root"
                    backup_dir=$(mktemp -d "$backup_root/$(date -u +%Y%m%dT%H%M%SZ).XXXXXX")
                fi
                mkdir -p -- "$backup_dir/$(dirname -- "$relative")"
                mv -- "$destination" "$backup_dir/$relative"
            fi
        fi
        if [[ ! -d "$destination" ]]; then
            mkdir -p -- "$destination"
            chmod --reference="$source" "$destination"
        fi
        continue
    fi

    mkdir -p -- "$(dirname -- "$destination")"
    if [[ -e "$destination" || -L "$destination" ]]; then
        if [[ -z "$backup_dir" ]]; then
            mkdir -p -- "$backup_root"
            backup_dir=$(mktemp -d "$backup_root/$(date -u +%Y%m%dT%H%M%SZ).XXXXXX")
        fi
        mkdir -p -- "$backup_dir/$(dirname -- "$relative")"
        mv -- "$destination" "$backup_dir/$relative"
    fi
    cp -a --no-preserve=ownership -- "$source" "$destination"
done

if [[ -n "$backup_dir" ]]; then
    printf 'Previous files backed up under: %s\n' "$backup_dir"
fi
printf 'Installed %d payload entries under %s\n' "${#entries[@]}" "$ROOT_DIR"
echo "Reload user services with: systemctl --user daemon-reload"
