from common import command_is_destructive, emit_permission_deny, extract_command, load_payload


payload = load_payload()
tool_name = payload.get("tool_name")
command = extract_command(payload)

if tool_name in {"Bash", "apply_patch"} and command_is_destructive(command):
    emit_permission_deny("Repository policy: destructive action requires explicit user direction outside hooks.")
