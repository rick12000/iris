# Directory Path Consistency

Vocalance writes to two root directories. Path layout is defined in
`vocalance/app/config/os_defaults.py`. Bootstrap scripts repeat the same directory
name literals and must stay aligned with that module.

## Owned Directories

| Name | Windows path | macOS path | Contents |
|---|---|---|---|
| Install root | `%LOCALAPPDATA%\Programs\Vocalance` | `~/Library/Application Support/Vocalance/runtime` | App code, venv, bundled tools. Written by setup scripts only. |
| User data root | `%APPDATA%\Vocalance` | `~/Library/Application Support/Vocalance` | Settings, marks, click history, sound/LLM models, logs. Written by the running app. |
| Launcher | Start Menu `Vocalance.lnk` | `~/Applications/Vocalance.app` | Entry point created by setup scripts. |

On macOS the install root is a `runtime` subdirectory of the user data root.

## Points That Must Stay Aligned

### Application directory name

The directory name `Vocalance` is `APPLICATION_DIR_NAME` in `os_defaults.py`.
`APPDATA_DIR_NAME` in `app_config.py` is that same constant.

| File | Variable |
|---|---|
| `vocalance/app/config/os_defaults.py` | `APPLICATION_DIR_NAME = "Vocalance"` |
| `vocalance/app/config/app_config.py` | `APPDATA_DIR_NAME = APPLICATION_DIR_NAME` |
| `scripts/bootstrapping/setup.ps1` | `'Vocalance'` in `$INSTALL_ROOT` / `$USER_DATA_DIR` |
| `scripts/bootstrapping/cleanup.ps1` | `'Vocalance'` in `$INSTALL_ROOT` / `$USER_DATA` |
| `scripts/bootstrapping/setup.sh` | `APPLICATION_DIR_NAME='Vocalance'` |
| `scripts/bootstrapping/cleanup.sh` | `APPLICATION_DIR_NAME='Vocalance'` |

`APPDATA_DIR_NAME` is also the value passed to `LoggingConfigModel(appdata_dir_name=...)`, so log files land under the same root automatically.

### Install root

| File | Variable |
|---|---|
| `vocalance/app/config/os_defaults.py` | `install_root()` |
| `scripts/bootstrapping/setup.ps1` | `$INSTALL_ROOT = Join-Path $env:LOCALAPPDATA 'Programs\Vocalance'` |
| `scripts/bootstrapping/cleanup.ps1` | `$INSTALL_ROOT = Join-Path $env:LOCALAPPDATA 'Programs\Vocalance'` |
| `scripts/bootstrapping/setup.sh` | `INSTALL_ROOT="${USER_DATA_DIR}/${MACOS_RUNTIME_SUBDIR}"` |

The app does not read the install root at runtime; it is a setup script concern only. `install_root()` exists so scripts and docs share one definition of the layout.

### User data subdirectories

All subdirectory names under the user data root are defined as fields on `StorageConfig` in `app_config.py`. The scripts wipe the entire user data root rather than individual subdirectories, so adding or renaming a subdir does **not** require touching the scripts.

## Update Checklist

**Renaming the user data root:** update `APPLICATION_DIR_NAME` in `os_defaults.py`, then update the matching literal in `setup.ps1`, `cleanup.ps1`, `setup.sh`, and `cleanup.sh`.

**Renaming the install root:** update `install_root()` in `os_defaults.py` and `$INSTALL_ROOT` / `INSTALL_ROOT` in the bootstrap scripts. On macOS also keep `MACOS_RUNTIME_SUBDIR` in `os_defaults.py` and `setup.sh` in sync.

## Verification

Confirm `APPLICATION_DIR_NAME` / `Vocalance` appears in `os_defaults.py`, `app_config.py`, and the four bootstrap scripts, and that Windows scripts still use `Programs\Vocalance` while macOS scripts use `Application Support` plus `runtime`.
