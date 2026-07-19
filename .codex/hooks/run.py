import os
import subprocess
import sys
from pathlib import Path


HOOKS = {
    "session_start": "session_start.py",
    "pre_tool_use": "pre_tool_use.py",
    "permission_request": "permission_request.py",
    "user_prompt_submit": "user_prompt_submit.py",
}


def current_repo_root() -> Path | None:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if result.returncode != 0 or not result.stdout.strip():
        return None
    return Path(result.stdout.strip()).resolve()


def main() -> None:
    hook_name = sys.argv[1] if len(sys.argv) == 2 else ""
    hook_file = HOOKS.get(hook_name)
    if hook_file is None:
        raise SystemExit("unknown hook")

    managed_repo_root = Path(__file__).resolve().parents[2]
    if current_repo_root() != managed_repo_root:
        return

    hook_path = Path(__file__).with_name(hook_file).resolve()
    os.execv(sys.executable, [sys.executable, str(hook_path)])


if __name__ == "__main__":
    main()
