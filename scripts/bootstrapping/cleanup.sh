#!/usr/bin/env bash
set -euo pipefail

APPLICATION_DIR_NAME='Vocalance'
MACOS_LAUNCHER_APP_NAME='Vocalance.app'

USER_DATA="${HOME}/Library/Application Support/${APPLICATION_DIR_NAME}"
LAUNCHER_APP="${HOME}/Applications/${MACOS_LAUNCHER_APP_NAME}"

removed=()
skipped=()

remove_if_exists() {
    local path="$1"
    local label="$2"
    if [[ -e "$path" ]]; then
        if rm -rf "$path"; then
            removed+=("$label")
        else
            echo "[error] Failed to remove ${label}" >&2
            skipped+=("${label} (in use or permission denied)")
        fi
    else
        skipped+=("${label} (not found)")
    fi
}

if [[ "$(id -u)" -eq 0 ]]; then
    echo "Run this uninstaller as your normal user, not as root." >&2
    exit 1
fi

remove_if_exists "$LAUNCHER_APP" "launcher (${LAUNCHER_APP})"
remove_if_exists "$USER_DATA" "application files and user data (${USER_DATA})"

echo ""
echo "=== Uninstall Summary ==="
if [[ ${#removed[@]} -gt 0 ]]; then
    echo "Removed:"
    for item in "${removed[@]}"; do
        echo "  - ${item}"
    done
fi
if [[ ${#skipped[@]} -gt 0 ]]; then
    echo "Skipped:"
    for item in "${skipped[@]}"; do
        echo "  - ${item}"
    done
fi
echo ""
