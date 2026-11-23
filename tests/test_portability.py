import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def clean_codex_config(config: str | None = None) -> str:
    result = subprocess.run(
        ["bash", str(ROOT / ".githooks/clean-codex-config")],
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
    windows_home = "C:" + r"\\Users\\Example Name"
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
CODEX_HOME = "{windows_home}\\\\.codex"
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
        "C:" + r"\Users\example\work\cache",
        "C:" + r"\\Users\\Example Name\\work\\cache",
        "/" + "Users/例 子/work/cache",
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
            ["bash", str(hook)], cwd=repo, text=True, capture_output=True, check=False
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


@pytest.mark.parametrize("shell", ["bash", "pwsh"])
def test_app_config_destinations(shell: str, tmp_path: Path) -> None:
    executable = shutil.which(shell)
    if executable is None:
        pytest.skip(f"{shell} is not installed")

    config = tmp_path / "xdg config"
    env = os.environ.copy()
    for name in (
        "MISE_GLOBAL_CONFIG_FILE",
        "MISE_CONFIG_DIR",
        "SHELDON_CONFIG_FILE",
        "SHELDON_CONFIG_DIR",
        "STARSHIP_CONFIG",
    ):
        env.pop(name, None)
    env["XDG_CONFIG_HOME"] = str(config)

    if shell == "bash":
        args = [
            executable, "--noprofile", "--norc", "-c",
            'source ./install_targets.sh; while read -r mode item; do '
            'printf "%s\\t%s\\t%s\\n" "$mode" "$item" "$(dotfile_destination "$item")"; '
            'done < install_targets.txt',
        ]
    else:
        args = [
            executable, "-NoProfile", "-Command",
            r'''
. ./install_targets.ps1
Get-DotfileTargets | ForEach-Object {
    $Item = [IO.Path]::GetRelativePath($PWD.Path, $_.Source).Replace('\', '/')
    "{0}`t{1}`t{2}" -f $_.Mode, $Item, $_.Target
}
''',
        ]

    def destinations() -> dict[str, tuple[str, Path]]:
        result = subprocess.check_output(args, cwd=ROOT, env=env, encoding="utf-8")
        return {
            item: (mode, Path(target))
            for mode, item, target in (line.split("\t") for line in result.splitlines())
        }

    mise = ".config/mise/config.toml"
    sheldon = ".config/sheldon/plugins.toml"
    starship = ".config/starship.toml"
    dsl = ".config/distill/dsl/global.json"
    targets = destinations()
    assert targets[mise] == ("copy", config / "mise/config.toml")
    assert targets[sheldon] == ("copy", config / "sheldon/plugins.toml")
    assert targets[starship] == ("link", config / "starship.toml")
    assert targets[dsl] == ("copy", config / "distill/dsl/global.json")

    env["MISE_CONFIG_DIR"] = str(tmp_path / "mise settings")
    env["SHELDON_CONFIG_DIR"] = str(tmp_path / "sheldon settings")
    targets = destinations()
    assert targets[mise] == ("copy", tmp_path / "mise settings/config.toml")
    assert targets[sheldon] == ("copy", tmp_path / "sheldon settings/plugins.toml")

    env["MISE_GLOBAL_CONFIG_FILE"] = str(tmp_path / "override/mise.toml")
    env["SHELDON_CONFIG_FILE"] = str(tmp_path / "override/sheldon.toml")
    env["STARSHIP_CONFIG"] = str(tmp_path / "override/starship.toml")
    targets = destinations()
    assert targets[mise] == ("copy", tmp_path / "override/mise.toml")
    assert targets[sheldon] == ("copy", tmp_path / "override/sheldon.toml")
    assert targets[starship] == ("link", tmp_path / "override/starship.toml")
