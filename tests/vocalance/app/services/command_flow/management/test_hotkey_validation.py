import pytest

from vocalance.app.config.hotkey_validation import custom_hotkey_error_message, custom_hotkey_placeholder, is_allowed_key, is_valid_custom_hotkey


@pytest.mark.parametrize(
    "token",
    [
        "a",
        "5",
        "ctrl",
        "alt",
        "shift",
        "win",
        "cmd",
        "fn",
        "enter",
        "tab",
        "space",
        "f1",
        "f12",
        "f24",
        "-",
        "/",
        "[",
        "CTRL",
        "Enter",
        "F5",
    ],
)
def test_is_allowed_key_accepts_recognised_tokens(token):
    assert is_allowed_key(token) is True


@pytest.mark.parametrize("token", ["", "   ", "custom", "macro", "f0", "f25", "ab"])
def test_is_allowed_key_rejects_unrecognised_tokens(token):
    assert is_allowed_key(token) is False


@pytest.mark.parametrize(
    "value",
    ["a", "ctrl+s", "ctrl+shift+k", "alt+f4", "ctrl+enter", "ctrl + s", "ctrl+alt+7"],
)
def test_is_valid_custom_hotkey_accepts_single_chord(value):
    assert is_valid_custom_hotkey(value) is True


@pytest.mark.parametrize(
    "value",
    ["", "   ", "ctrl+c, ctrl+v", "a,b", "ctrl+c;ctrl+v", "ctrl+custom", "macro"],
)
def test_is_valid_custom_hotkey_rejects_invalid(value):
    assert is_valid_custom_hotkey(value) is False


@pytest.mark.parametrize("macos, modifier", [(False, "ctrl"), (True, "command")])
def test_custom_hotkey_placeholder_uses_primary_modifier(macos, modifier, monkeypatch):
    monkeypatch.setattr("vocalance.app.config.hotkey_validation.running_on_macos", lambda: macos)
    monkeypatch.setattr("vocalance.app.config.hotkey_validation.primary_modifier_key", lambda: modifier)
    assert custom_hotkey_placeholder() == f"e.g. {modifier}+alt+7"
    assert modifier in custom_hotkey_error_message()


@pytest.mark.parametrize("value", ["command+c", "command+shift+z", "ctrl+alt+7"])
def test_is_valid_custom_hotkey_accepts_command_chords(value):
    assert is_valid_custom_hotkey(value) is True
