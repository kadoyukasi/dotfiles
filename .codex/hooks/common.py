import json
import re
import sys
from typing import Any


PROTECTED_PATHS = (
    ".codex/hooks.json",
    ".codex/config.toml",
    ".githooks/pre-commit",
    "install.sh",
    "install.ps1",
    "uninstall.sh",
    "uninstall.ps1",
    "README.md",
)

SECRET_PATTERNS = (
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(r"\bghp_[A-Za-z0-9]{36}\b"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{82,}\b"),
    re.compile(r"\bsk-[A-Za-z0-9]{20,}\b"),
    re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b"),
)

DESTRUCTIVE_COMMAND_PATTERNS = (
    re.compile(r"(^|\s)rm\s+-rf(\s|$)"),
    re.compile(r"(^|\s)git\s+reset\s+--hard(\s|$)"),
    re.compile(r"(^|\s)git\s+checkout\s+--(\s|$)"),
    re.compile(r"(^|\s)git\s+clean\s+-fdx?(\s|$)"),
    re.compile(r"(^|\s)del\s+/f(\s|$)", re.IGNORECASE),
    re.compile(r"(^|\s)format(\s|$)", re.IGNORECASE),
    re.compile(r"Remove-Item\b.*-Recurse\b.*-Force\b", re.IGNORECASE),
)


def load_payload() -> dict[str, Any]:
    raw = sys.stdin.read()
    if not raw.strip():
        return {}
    return json.loads(raw)


def emit_json(payload: dict[str, Any]) -> None:
    json.dump(payload, sys.stdout)
    sys.stdout.write("\n")


def emit_pretool_deny(reason: str) -> None:
    emit_json(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }
    )


def emit_permission_deny(reason: str) -> None:
    emit_json(
        {
            "hookSpecificOutput": {
                "hookEventName": "PermissionRequest",
                "decision": {
                    "behavior": "deny",
                    "message": reason,
                },
            }
        }
    )


def emit_additional_context(event_name: str, message: str) -> None:
    emit_json(
        {
            "hookSpecificOutput": {
                "hookEventName": event_name,
                "additionalContext": message,
            }
        }
    )


def command_is_destructive(command: str) -> bool:
    return any(pattern.search(command) for pattern in DESTRUCTIVE_COMMAND_PATTERNS)


def text_contains_secret(text: str) -> bool:
    return any(pattern.search(text) for pattern in SECRET_PATTERNS)


def extract_command(payload: dict[str, Any]) -> str:
    tool_input = payload.get("tool_input")
    if isinstance(tool_input, dict):
        command = tool_input.get("command")
        if isinstance(command, str):
            return command
    return ""


def patch_touches_protected_paths(command: str) -> bool:
    return any(path in command for path in PROTECTED_PATHS)


def command_touches_protected_paths(command: str) -> bool:
    lowered = command.lower()
    return any(path.lower() in lowered for path in PROTECTED_PATHS)
