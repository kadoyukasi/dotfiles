from pathlib import Path
import sys


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / ".codex" / "hooks"))

from common import (  # noqa: E402
    command_is_destructive,
    command_touches_protected_paths,
    patch_touches_protected_paths,
    text_contains_secret,
)


def test_detects_destructive_shell_commands() -> None:
    assert command_is_destructive("rm -rf /tmp/example")
    assert command_is_destructive("git reset --hard HEAD~1")
    assert command_is_destructive("Remove-Item foo -Recurse -Force")
    assert not command_is_destructive("git status --short")


def test_detects_protected_paths_in_commands() -> None:
    assert command_touches_protected_paths("Get-Content .codex/config.toml -Raw")
    assert command_touches_protected_paths("cat README.md")
    assert not command_touches_protected_paths("cat Brewfile")


def test_detects_protected_paths_in_patch_payload() -> None:
    patch = "*** Update File: .codex/hooks.json\n+{}\n"
    assert patch_touches_protected_paths(patch)
    assert not patch_touches_protected_paths("*** Update File: Brewfile\n")


def test_detects_secret_like_prompt_content() -> None:
    assert text_contains_secret("sk-abcdefghijklmnopqrstuvwxyz123456")
    key_header = "-----BEGIN " + "OPENSSH PRIVATE KEY" + "-----"
    assert text_contains_secret(key_header)
    assert not text_contains_secret("please update hooks.json")
