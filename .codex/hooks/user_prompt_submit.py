from common import emit_additional_context, load_payload, text_contains_secret


payload = load_payload()
prompt = payload.get("prompt")

if isinstance(prompt, str) and text_contains_secret(prompt):
    print('{"decision":"block","reason":"Potential secret detected in user prompt. Remove or redact it before continuing."}')
elif isinstance(prompt, str) and "hook" in prompt.lower():
    emit_additional_context(
        "UserPromptSubmit",
        (
            "When changing Codex hooks, keep behavior repo-scoped unless the user "
            "explicitly asks for global or plugin-level rollout. Prefer context-mode "
            "for large input handling and reserve distill for final user-facing compression."
        ),
    )
