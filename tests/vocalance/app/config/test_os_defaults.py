import os
from pathlib import Path

from vocalance.app.config.os_defaults import (
    APPLICATION_DIR_NAME,
    MACOS_ICON_FILENAME,
    MACOS_LAUNCHER_APP_NAME,
    MACOS_RUNTIME_SUBDIR,
    WINDOWS_ICON_FILENAME,
    application_icon_filename,
    install_root,
    macos_launcher_app_path,
    primary_modifier_key,
    user_data_root,
)


def test_user_data_and_install_paths_on_windows(windows_platform):
    data_root = user_data_root()
    assert data_root == os.path.join(r"C:\Users\test\AppData\Roaming", APPLICATION_DIR_NAME)
    assert install_root() == os.path.join(r"C:\Users\test\AppData\Local", "Programs", APPLICATION_DIR_NAME)
    assert primary_modifier_key() == "ctrl"
    assert application_icon_filename() == WINDOWS_ICON_FILENAME


def test_user_data_and_install_paths_on_macos(macos_platform):
    data_root = user_data_root()
    assert data_root == str(Path.home() / "Library" / "Application Support" / APPLICATION_DIR_NAME)
    assert install_root() == os.path.join(data_root, MACOS_RUNTIME_SUBDIR)
    assert macos_launcher_app_path() == str(Path.home() / "Applications" / MACOS_LAUNCHER_APP_NAME)
    assert primary_modifier_key() == "command"
    assert application_icon_filename() == MACOS_ICON_FILENAME
