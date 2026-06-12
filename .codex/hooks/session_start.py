from common import emit_additional_context


emit_additional_context(
    "SessionStart",
    (
        "This repo manages machine-level dotfiles. install/uninstall scripts and "
        "global git core.hooksPath behavior must stay in sync with README and "
        ".githooks/pre-commit. Treat .codex/hooks.json and .codex/config.toml as "
        "behavioral configuration changes, not cosmetic edits. Prefer context-mode "
        "tools for large inputs: use ctx_execute/ctx_execute_file for analysis, "
        "ctx_index+ctx_search for large references, and keep distill as the "
        "user-visible summary layer."
    ),
)
