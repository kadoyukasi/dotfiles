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
            "This command touches install/hook/Codex config files. Keep install and "
            "uninstall flows aligned, update README when user-visible behavior changes, "
            "and preserve context-mode-first routing for large inputs."
        ),
    )
elif tool_name == "apply_patch" and patch_touches_protected_paths(command):
    emit_additional_context(
        "PreToolUse",
        (
            "This patch changes install/hook/Codex config files. Preserve existing "
            "user changes, keep cross-platform behavior aligned, document behavior "
            "changes, and keep context-mode ahead of distill for large-data workflows."
        ),
    )
