import pytest

from vocalance.app.config.automation_command_registry import AutomationCommandRegistry


@pytest.mark.parametrize(
    "macos, command_key, expected",
    [
        (False, "copy", "ctrl+c"),
        (True, "copy", "command+c"),
        (False, "paste", "ctrl+v"),
        (True, "paste", "command+v"),
        (False, "close", "alt+f4"),
        (True, "close", "command+w"),
        (False, "redo", "ctrl+y"),
        (True, "redo", "command+shift+z"),
        (False, "save", "ctrl+s"),
        (True, "save", "command+s"),
        (False, "minimize", "alt+space, n"),
        (True, "minimize", "command+m"),
    ],
)
def test_default_command_chords_follow_os(macos, command_key, expected, monkeypatch):
    monkeypatch.setattr("vocalance.app.config.automation_command_registry.running_on_macos", lambda: macos)
    commands = {cmd.command_key: cmd for cmd in AutomationCommandRegistry.get_default_commands()}
    assert commands[command_key].action_value == expected


@pytest.mark.parametrize("macos, expected_type", [(False, "key_sequence"), (True, "hotkey")])
def test_minimize_action_type_follows_os(macos, expected_type, monkeypatch):
    monkeypatch.setattr("vocalance.app.config.automation_command_registry.running_on_macos", lambda: macos)
    commands = {cmd.command_key: cmd for cmd in AutomationCommandRegistry.get_default_commands()}
    assert commands["minimize"].action_type == expected_type


@pytest.mark.parametrize("macos, desk_present", [(False, True), (True, False)])
def test_desk_commands_only_on_windows(macos, desk_present, monkeypatch):
    monkeypatch.setattr("vocalance.app.config.automation_command_registry.running_on_macos", lambda: macos)
    phrases = AutomationCommandRegistry.get_protected_phrases()
    assert ("right desk" in phrases) is desk_present
    assert ("left desk" in phrases) is desk_present
