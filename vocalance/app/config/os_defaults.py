import os
import sys
from pathlib import Path

APPLICATION_DIR_NAME = "Vocalance"
WINDOWS_ICON_FILENAME = "icon.ico"
MACOS_ICON_FILENAME = "grey_icon_full_size.png"
MACOS_RUNTIME_SUBDIR = "runtime"
MACOS_LAUNCHER_APP_NAME = "Vocalance.app"


def running_on_windows() -> bool:
    return sys.platform == "win32"


def running_on_macos() -> bool:
    return sys.platform == "darwin"


def primary_modifier_key() -> str:
    return "command" if running_on_macos() else "ctrl"


def user_data_parent_dir() -> str:
    if running_on_windows():
        return os.environ.get("APPDATA", os.path.expanduser("~"))
    if running_on_macos():
        return str(Path.home() / "Library" / "Application Support")
    return os.path.expanduser("~")


def user_data_root(app_dir_name: str = APPLICATION_DIR_NAME) -> str:
    return os.path.join(user_data_parent_dir(), app_dir_name)


def install_root(app_dir_name: str = APPLICATION_DIR_NAME) -> str:
    if running_on_windows():
        local = os.environ.get("LOCALAPPDATA", os.path.expanduser("~"))
        return os.path.join(local, "Programs", app_dir_name)
    if running_on_macos():
        return os.path.join(user_data_parent_dir(), app_dir_name, MACOS_RUNTIME_SUBDIR)
    return os.path.join(os.path.expanduser("~"), app_dir_name)


def macos_launcher_app_path() -> str:
    return str(Path.home() / "Applications" / MACOS_LAUNCHER_APP_NAME)


def application_icon_filename() -> str:
    return MACOS_ICON_FILENAME if running_on_macos() else WINDOWS_ICON_FILENAME
