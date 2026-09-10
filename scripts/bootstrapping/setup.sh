#!/usr/bin/env bash
set -euo pipefail

VOCALANCE_VERSION='0.1.0'
VOCALANCE_REPO='rick12000/vocalance'
APPLICATION_DIR_NAME='Vocalance'
MACOS_RUNTIME_SUBDIR='runtime'
MACOS_LAUNCHER_APP_NAME='Vocalance.app'

UV_VERSION='0.11.22'
UV_ARCHIVE_SHA256='97a45e2ff8d5ea262623eed57ec2d9c468a42d74496d5c3c3eef11340235bd7f'

USER_DATA_DIR="${HOME}/Library/Application Support/${APPLICATION_DIR_NAME}"
INSTALL_ROOT="${USER_DATA_DIR}/${MACOS_RUNTIME_SUBDIR}"
TOOLS_DIR="${INSTALL_ROOT}/tools"
APP_DIR="${INSTALL_ROOT}/app"
VENV_DIR="${INSTALL_ROOT}/env"
UV_BIN="${TOOLS_DIR}/uv"
LAUNCHER_APP="${HOME}/Applications/${MACOS_LAUNCHER_APP_NAME}"

is_yes() {
    local raw
    raw="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
    raw="${raw#"${raw%%[![:space:]]*}"}"
    raw="${raw%"${raw##*[![:space:]]}"}"
    [[ "$raw" == "yes" || "$raw" == "y" ]]
}

verified_download() {
    local uri="$1"
    local out_path="$2"
    local expected="$3"
    curl -fsSL "$uri" -o "$out_path"
    local actual
    actual="$(shasum -a 256 "$out_path" | awk '{print $1}')"
    if [[ "$actual" != "$expected" ]]; then
        rm -f "$out_path"
        echo "Integrity check failed for '$(basename "$out_path")'." >&2
        echo "  Expected : $expected" >&2
        echo "  Computed : $actual" >&2
        exit 1
    fi
}

write_launcher_app() {
    local python_bin="$1"
    local main_script="$2"
    local icon_src="$3"
    local macos_dir="${LAUNCHER_APP}/Contents/MacOS"
    local resources_dir="${LAUNCHER_APP}/Contents/Resources"
    mkdir -p "$macos_dir" "$resources_dir"
    if [[ -f "$icon_src" ]]; then
        cp "$icon_src" "${resources_dir}/AppIcon.png"
    fi
    cat > "${LAUNCHER_APP}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Vocalance</string>
    <key>CFBundleIdentifier</key>
    <string>com.vocalance.app</string>
    <key>CFBundleName</key>
    <string>Vocalance</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VOCALANCE_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VOCALANCE_VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Vocalance uses the microphone for voice commands and dictation.</string>
</dict>
</plist>
EOF
    cat > "${macos_dir}/Vocalance" <<EOF
#!/bin/bash
exec "${python_bin}" "${main_script}"
EOF
    chmod +x "${macos_dir}/Vocalance"
}

if [[ "$(id -u)" -eq 0 ]]; then
    echo "Run this installer as your normal user, not as root." >&2
    exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This installer is for macOS." >&2
    exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
    echo "This installer supports Apple Silicon (arm64) only." >&2
    exit 1
fi

STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/VocalanceSetup.XXXXXX")"
trap 'rm -rf "$STAGE_DIR"' EXIT

uv_tar_name="uv-aarch64-apple-darwin.tar.gz"
uv_tar_url="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${uv_tar_name}"
uv_tar_path="${STAGE_DIR}/${uv_tar_name}"

echo "Downloading uv ${UV_VERSION} (aarch64-apple-darwin)..."
verified_download "$uv_tar_url" "$uv_tar_path" "$UV_ARCHIVE_SHA256"

uv_extract_dir="${STAGE_DIR}/uv-extract"
mkdir -p "$uv_extract_dir"
tar -xzf "$uv_tar_path" -C "$uv_extract_dir"
uv_binary=""
while IFS= read -r -d '' candidate; do
    uv_binary="$candidate"
    break
done < <(find "$uv_extract_dir" -name uv -type f -print0)
if [[ -z "$uv_binary" ]]; then
    echo "uv binary not found in downloaded archive." >&2
    exit 1
fi

mkdir -p "$TOOLS_DIR"
cp "$uv_binary" "$UV_BIN"
chmod +x "$UV_BIN"

if [[ -d "$APP_DIR" ]]; then
    read -r -p "Vocalance is already installed at ${INSTALL_ROOT}. Reinstall? (yes/no) " answer
    if ! is_yes "$answer"; then
        exit 0
    fi
    rm -rf "$APP_DIR"
    if [[ -d "$VENV_DIR" ]]; then
        rm -rf "$VENV_DIR"
    fi
fi

zip_name="vocalance-v${VOCALANCE_VERSION}.zip"
zip_url="https://github.com/${VOCALANCE_REPO}/releases/download/v${VOCALANCE_VERSION}/${zip_name}"
zip_path="${STAGE_DIR}/${zip_name}"

echo "Downloading Vocalance v${VOCALANCE_VERSION}..."
curl -fsSL "$zip_url" -o "$zip_path"

mkdir -p "$APP_DIR"
unzip -q -o "$zip_path" -d "$APP_DIR"

echo "Creating virtual environment..."
"$UV_BIN" venv --python 3.13.9 "$VENV_DIR"

read -r -p "Enable LLM features? (requires ~2 GB and Xcode Command Line Tools) (yes/no) " llm_answer

echo "Installing dependencies..."
export VIRTUAL_ENV="$VENV_DIR"
export UV_PROJECT_ENVIRONMENT="$VENV_DIR"
if is_yes "$llm_answer"; then
    "$UV_BIN" sync --directory "$APP_DIR" --frozen --extra llm
else
    "$UV_BIN" sync --directory "$APP_DIR" --frozen
fi

main_script="${APP_DIR}/vocalance.py"
python_bin="${VENV_DIR}/bin/python"
icon_path="${APP_DIR}/vocalance/app/assets/logo/grey_icon_full_size.png"
mkdir -p "${HOME}/Applications"
write_launcher_app "$python_bin" "$main_script" "$icon_path"

echo "Setup complete. Launch Vocalance from ~/Applications/${MACOS_LAUNCHER_APP_NAME}."
echo "Grant Microphone and Accessibility permission when macOS asks, or in System Settings > Privacy & Security."
