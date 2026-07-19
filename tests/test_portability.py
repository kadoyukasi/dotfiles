import json
import re
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_managed_configs_parse() -> None:
    hooks = json.loads(read(".codex/hooks.json"))
    tomllib.loads(read(".codex/config.toml"))

    commands = [
        hook["command"]
        for groups in hooks["hooks"].values()
        for group in groups
        for hook in group["hooks"]
    ]
    assert all("hooks/run.py" in command for command in commands)
    assert all("git rev-parse" not in command for command in commands)


def test_codex_hook_dispatcher_is_repo_scoped() -> None:
    dispatcher = ROOT / ".codex/hooks/run.py"

    inside = subprocess.run(
        [sys.executable, str(dispatcher), "session_start"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=True,
    )
    payload = json.loads(inside.stdout)
    assert payload["hookSpecificOutput"]["hookEventName"] == "SessionStart"

    with tempfile.TemporaryDirectory() as directory:
        subprocess.run(["git", "init", "-q"], cwd=directory, check=True)
        outside = subprocess.run(
            [sys.executable, str(dispatcher), "session_start"],
            cwd=directory,
            text=True,
            capture_output=True,
            check=True,
        )
    assert outside.stdout == ""
    assert outside.stderr == ""


def test_codex_config_has_no_machine_generated_state() -> None:
    config = read(".codex/config.toml")
    assert not re.search(r'^\[projects\."', config, re.MULTILINE)
    assert "[hooks.state]" not in config
    assert not re.search(r"^\[marketplaces\.", config, re.MULTILINE)
    assert not re.search(r"/(?:Users|home)/[^/]+/", config)
    assert not re.search(r'^[A-Za-z]:[\\/]', config, re.MULTILINE)


def test_codex_config_clean_filter_removes_only_machine_state() -> None:
    sample = """model = \"gpt-5.6\"

[projects.\"/Users/example/work/repo\"]
trust_level = \"trusted\"

[hooks.state]

[hooks.state.\"/Users/example/.codex/hooks.json:session_start:0:0\"]
trusted_hash = \"sha256:abc\"

[marketplaces.\"example\"]
revision = \"local-cache\"

[features]
hooks = true
"""
    result = subprocess.run(
        [str(ROOT / ".githooks/clean-codex-config")],
        input=sample,
        text=True,
        capture_output=True,
        check=True,
    )

    assert result.stdout == 'model = "gpt-5.6"\n\n[features]\nhooks = true\n'


def test_cross_platform_script_contract() -> None:
    installer = read("install.ps1")
    pre_commit = read(".githooks/pre-commit")
    attributes = read(".gitattributes")

    assert "sudo pwsh" not in installer
    assert "[[:space:]]*[:=][[:space:]]*" in pre_commit
    assert ".githooks/* text eol=lf" in attributes
    assert "*.sh text eol=lf" in attributes
    assert ".codex/config.toml filter=codex-config" in attributes

    for script in (read("install.sh"), installer):
        assert "filter.codex-config.clean" in script
        assert "filter.codex-config.required" in script

    for script in (read("uninstall.sh"), read("uninstall.ps1")):
        assert "--remove-section filter.codex-config" in script
