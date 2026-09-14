from common import emit_additional_context, load_payload, text_contains_secret


payload = load_payload()
prompt = payload.get("prompt")

if isinstance(prompt, str) and text_contains_secret(prompt):
    print('{"decision":"block","reason":"Potential secret detected in user prompt. Remove or redact it before continuing."}')
elif isinstance(prompt, str) and "hook" in prompt.lower():
    emit_additional_context(
        "UserPromptSubmit",
        (
            "Keep Codex hooks repo-scoped unless global rollout is explicit; use "
            "context-mode for large inputs."
        ),
    )
