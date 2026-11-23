---
name: distill
description: Compress a final user-facing result when the user explicitly requests distill or unusually terse S/C/D/R/O/P output. Do not use for routine conversation, raw logs, or test evidence.
---

# Distill

Apply to the requested result. Keep other replies in their usual style. Compress the prompt itself only on explicit request.

## Core Rule

Talk with the user in distill language:

- Use the user's language unless they specify one
- Use AR-0 or AR-1
- short command lines
- fixed semantic prefixes
- semantic atoms over natural phrases
- one idea per line
- explicit constraints
- explicit pass criteria
- exact paths, commands, env vars, IDs when useful
Default to AR-1 (short phrases with enough grammar for clarity). Use AR-0 (terse fragments) when requested or unambiguous.

## Prefixes and shorthand

- `S` status, `C` cause or context, `D` action or decision, `R` risk or blocker, `O` outcome or output, `N` constraint, `P` pass criteria or evidence.
- Interpret existing shorthand when shared. `A` auth, `B` backend, `F` frontend, `E` end-to-end, `V` environment, `X` dependencies, `U` interface, `DB` database, `CFG` configuration, `DOC` documentation, `PERM` permissions.
- Macros `1` failing test first, `2` relevant tests, `3` report, `4` review, `5` smallest safe fix, `6` validate, `7` commit and push, `8` create or update pull request, `9` release or publish, `0` exact raw output.
- Defaults `N1` keep frontend, `N2` keep backend, `N3` keep UI, `N4` avoid broad refactor, `N5` preserve user changes, `N6` interactive command.

## Example

```text
O Fixed empty-config handling in config.py
P 12 focused tests passed
R Production rollout pending
```

## Glossary and memory

Use aliases only when they clarify repeated terms. Define each new `#` + letter + digit alias in one `Dict:` line. Use `Dict+:` to extend an existing glossary. Reuse each alias for the same meaning throughout the thread. Leave secrets, people, IDs, paths, URLs, and one-off terms unaliased.

Only on explicit learning request, run `distill dsl learn-thread --stdin` with a reviewed, sanitized transcript. Let the CLI manage its glossary files.

## Tools

Format the final result directly. If calling the `distill` CLI to compress that result, specify the exact fields and output format, then wait for it to finish. Keep tests, builds, lint, diffs, security and permission checks, infrastructure plans, and interactive commands outside the CLI. Base decisions on the original evidence.

## Keep Explicit

- security
- permissions
- payment
- data loss
- migrations
- production
- destructive actions
- user-facing behavior
- test expectations
- exact paths, endpoints, commands, env vars, IDs

## Quality Gate

Before returning, check:

- Did you answer the user instead of rewriting their prompt?
- Are constraints explicit?
- Is success defined when relevant?
- Did compression remove meaning?
- Are aliases obvious or defined?
- Is the answer short but still safe?

If not, use more words.
