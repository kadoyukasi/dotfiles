from common import (
    command_is_destructive,
    command_touches_protected_paths,
    emit_additional_context,
    emit_pretool_deny,
    extract_command,
    load_payload,
    patch_touches_protected_paths,
)


payload = load_payload()
tool_name = payload.get("tool_name")
command = extract_command(payload)

if tool_name == "Bash" and command_is_destructive(command):
    emit_pretool_deny("Repository policy: destructive shell command blocked. Use a safer scoped alternative.")
elif tool_name == "Bash" and command_touches_protected_paths(command):
    emit_additional_context(
        "PreToolUse",
        (
            "Protected dotfiles touched: keep install/uninstall and README aligned; "
            "use context-mode for large inputs."
        ),
    )
elif tool_name == "apply_patch" and patch_touches_protected_paths(command):
    emit_additional_context(
        "PreToolUse",
        (
            "Protected dotfiles changed: preserve user work, cross-platform behavior, "
            "and README alignment; use context-mode for large inputs."
        ),
    )
