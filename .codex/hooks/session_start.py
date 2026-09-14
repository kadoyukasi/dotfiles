from common import emit_additional_context


emit_additional_context(
    "SessionStart",
    (
        "Machine-level dotfiles: keep install/uninstall, README, .githooks/pre-commit, "
        "and core.hooksPath behavior aligned. Treat Codex config as behavioral; use "
        "context-mode for large inputs."
    ),
)
