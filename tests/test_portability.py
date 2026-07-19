import json
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def clean_codex_config(config: str | None = None) -> str:
    result = subprocess.run(
        [str(ROOT / ".githooks/clean-codex-config")],
        input=read(".codex/config.toml") if config is None else config,
        text=True,
        capture_output=True,
        check=True,
    )
    return result.stdout


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
    config = clean_codex_config()
    assert not re.search(r'^\[projects\."', config, re.MULTILINE)
    assert "[hooks.state]" not in config
    assert not re.search(r"^\[marketplaces\.", config, re.MULTILINE)
    assert not re.search(r"/(?:Users|home)/[^/]+/", config)
    assert not re.search(r'^[A-Za-z]:[\\/]', config, re.MULTILINE)


def test_codex_config_clean_filter_removes_only_machine_state() -> None:
    machine_home = "/" + "Users/example"
    windows_home = "C:" + "\\Users\\example"
    sample = f"""model = \"gpt-5.6\"
notify = [\"{machine_home}/bin/notifier\"]

[projects.\"{machine_home}/work/repo\"]
trust_level = \"trusted\"

[hooks.state]

[hooks.state.\"{machine_home}/.codex/hooks.json:session_start:0:0\"]
trusted_hash = \"sha256:abc\"

[marketplaces.\"example\"]
revision = \"local-cache\"

[features]
hooks = true

[mcp_servers.node_repl.env]
CODEX_HOME = '{windows_home}\\.codex'
NODE_REPL_TRUSTED_CODE_PATHS = \"{machine_home}/.codex\"
PORTABLE_VALUE = \"kept\"
"""
    assert clean_codex_config(sample) == (
        'model = "gpt-5.6"\n\n'
        '[features]\nhooks = true\n\n'
        '[mcp_servers.node_repl.env]\nPORTABLE_VALUE = "kept"\n'
    )


def test_tracked_files_have_no_machine_local_home_paths() -> None:
    tracked = subprocess.check_output(
        ["git", "ls-files", "-z"], cwd=ROOT
    ).decode().split("\0")
    patterns = (
        re.compile(r"/(?:Users|home)/[A-Za-z0-9._-]+/"),
        re.compile(r"[A-Za-z]:[\\/]Users[\\/][A-Za-z0-9._-]+[\\/]"),
    )
    violations = []

    for path in filter(None, tracked):
        if path == ".codex/config.toml":
            content = clean_codex_config()
        else:
            raw = (ROOT / path).read_bytes()
            if b"\0" in raw:
                continue
            try:
                content = raw.decode("utf-8")
            except UnicodeDecodeError:
                continue
        if any(pattern.search(content) for pattern in patterns):
            violations.append(path)

    assert violations == []


def test_pre_commit_blocks_machine_local_home_paths() -> None:
    machine_paths = (
        "/" + "Users/example/work/cache",
        "/" + "home/example/work/cache",
        "C:" + "\\Users\\example\\work\\cache",
    )
    with tempfile.TemporaryDirectory() as directory:
        repo = Path(directory)
        subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
        hook = repo / "pre-commit"
        shutil.copy2(ROOT / ".githooks/pre-commit", hook)
        for index, machine_path in enumerate(machine_paths):
            (repo / f"leak-{index}.txt").write_text(machine_path, encoding="utf-8")
        subprocess.run(["git", "add", "."], cwd=repo, check=True)
        result = subprocess.run(
            [str(hook)], cwd=repo, text=True, capture_output=True, check=False
        )

    assert result.returncode == 1
    for index in range(len(machine_paths)):
        assert f"blocked machine-local home path in: leak-{index}.txt" in result.stdout


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
