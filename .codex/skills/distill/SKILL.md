---
name: distill
description: Compress a final user-facing result when the user explicitly requests distill or unusually terse S/C/D/R/O/P output. Do not use for routine conversation, raw logs, or test evidence.
---

# Distill

Use only when the user invokes `/distill` or explicitly asks for distill language.

Apply it to the requested result, not automatically to the whole thread.

Do not return the user's prompt compressed as an artifact.
Return to normal prose after that result unless the user explicitly asks to continue.

## Core Rule

Talk with the user in distill language:

- English only, unless user explicitly requests another output language
- Military English + AR-0/AR-1 baseline
- short command lines
- fixed semantic prefixes
- semantic atoms over natural phrases
- one idea per line
- explicit constraints
- explicit pass criteria
- exact paths, commands, env vars, IDs when useful
- no filler
- no cryptic code
- no long prose unless user asks for explanation

Compress meaning, not characters.
Big wins come from removing repetition, sharing glossary, sharing context, and sharing structure.

Default line grammar:

```text
<prefix> <semantic-atoms>
```

Prefer:

```text
S glab auth fail gitlab.com
D inspect remotes + MR meta
R merge/update may block w/o token
```

Avoid:

```text
Status: glab auth reports fail for gitlab.com. I will still inspect local remotes and MR metadata; merge/update may block if token/session is missing.
```

AR levels:

- `AR-0` terse atoms, minimum grammar, still clear
- `AR-1` atoms + small glue for safety/clarity
- default to `AR-1`; use `AR-0` only when meaning stays obvious

## Thread Behavior

For the explicitly requested distill result:

- use distill language only for the requested result
- use distill structure for a final summary, review result, or other explicitly named output
- do not wrap every answer in `Best`, `More aggressive`, or `Tradeoff`
- do not output a rewritten/compressed version of the user's latest prompt unless user explicitly asks to compress text
- keep hidden chain-of-thought private; never reveal it
- keep unrelated status updates and later turns in the user's normal language

## Stable DSL

Always use the shared dict when aliases or prefixes matter.
Emit `Dict:` early in a thread or after changing meanings.

Core prefixes:

- `S` state/status
- `C` cause/context
- `D` action/decision
- `R` risk/blocker
- `O` outcome/output
- `N` constraint/no-go
- `P` pass criteria/proof

Optional task labels:

- `A` authentication or authorization
- `B` backend
- `F` frontend
- `E` end-to-end tests
- `V` environment
- `X` dependencies
- `U` user interface
- `DB` database
- `CFG` configuration
- `DOC` documentation
- `PERM` permissions

Built-in macros:

- `1` add failing regression test first
- `2` run relevant tests
- `3` report summary, files, tests, and status
- `4` review for bugs, regressions, security, and risks
- `5` implement smallest safe fix
- `6` validate with tests or checks
- `7` commit and push changes
- `8` create or update pull request
- `9` release or publish flow
- `0` exact raw output required

Built-in defaults:

- `N1` do not change frontend
- `N2` do not change backend
- `N3` do not change UI
- `N4` no broad refactor
- `N5` preserve unrelated user changes
- `N6` interactive or TUI command

Example:

```text
Dict: S=state C=context D=action R=risk O=outcome N=no-go P=proof
S auth bug reproduced
D add failing auth test
D patch B auth guard
N F/UI unchanged
P invalid token denied + valid user allowed
P bun test auth PASS
```

Use DSL only when the user and agent share the glossary. If meaning may be ambiguous, use the full phrase.

## AR Style

Prefer semantic atoms:

```text
D sync repo/pkg/bin skill
R PATH pkg bin may shadow repo
O minimal patch set
```

Avoid natural filler:

```text
D patch repo skill + packaged skill + installed skill if needed
R may need rebuild/install if PATH uses packaged binary
```

Use arrows for transforms:

```text
D migrate labels -> AR-1 cmds
D verbose status -> S/D/R atoms
```

Use `=>` for causal/risk relation:

```text
C PATH pkg bin => repo patch ignored
R missing token => merge blocked
```

## Variable Dict

Use DSL/Dict only when it makes the requested compressed result clearer.
Start with `Dict:` only when meanings are not already shared.
Scan only the requested result for repeated stable terms that would compress well.
Define a short variable only when a stable noun or phrase appears at least 3 times.
Prefer variables for repeated project nouns, package nouns, component names, workflow names, and repeated technical objects.
The model chooses the variables dynamically from the current task; there is no fixed variable list.
Visible transcript is the canonical Dict state; do not rely on hidden reasoning as storage.
At each new response, update `Dict:` only with newly introduced variables.
Do not repeat variables already defined earlier in the thread or already present in known DSL memory.
If the response introduces no new variable, omit `Dict:` instead of restating old definitions.
After defining any `Dict` alias or inline variable, run a substitution pass: every later safe occurrence of that meaning must use the alias/key.
Keep the full term only when exact spelling is required for a model ID, package name, path, URL, quoted text, or disambiguation.

```text
S cache=#c1 warmed model=#m1
D inspect #c1 hit rate
D compare #m1 latency
N no extra vars for one-off nouns
```

After definition, use the variable:

```text
D tune #c1 ttl
D benchmark #m1 output
```

Rules:

- variable key format: `#` + letter + digit
- one stable meaning per variable inside the thread
- do not define variables for secrets, people, IDs, paths, URLs, or one-off terms
- do not redefine an active variable; add a new key if meaning changed
- inline `#` variables are thread-local immediately after explicit assignment
- persist variables only when the user explicitly requests learning from a sanitized transcript
- never persist secrets, personal information, credentials, paths, URLs, or unreviewed conversation text

## Good Response Forms

Tiny status:

```text
S done
O changed src/onboarding.ts + test/cli-entry.test.ts
P bun test PASS
```

Plan:

```text
Dict: S=state C=context D=action R=risk O=outcome N=no-go P=proof
S fix onboarding distill mode
D inspect skill/rules
D patch wording + sync copies
D run focused tests
N unrelated refactor
P /distill changes conversation style, not prompt output
O files + tests + risks
```

Need info:

```text
R need target repo/file
C prompt lacks safe path
```

Review/result:

```text
O PASS
O skill activates thread language mode
P bun test test/cli-entry.test.ts PASS
R not committed
```

## Glossary And Memory

Use two memory layers:

- thread dict: internal aliases for the current conversation
- persisted dict: entries saved by `distill dsl learn`, `distill dsl learn-thread --stdin`, or explicit user action

Do not manually create memory files. Let the `distill` CLI own JSON memory writes.

Use aliases only when they stay obvious:

- `be` backend
- `fe` frontend
- `db` database
- `e2e` end-to-end
- `cfg` config
- `docs` documentation
- `env` environment
- `deps` dependencies
- `repo` repository
- `impl` implementation
- `ref` refactor/reference
- `err` error

When aliases help the user, output one compact line:

```text
Dict: S=state C=context D=action R=risk O=outcome N=no-go P=proof B=backend F=frontend
```

Later additions:

```text
Dict+: P1=extra permission rule
```

Avoid aliases for rare, short, temporary, or ambiguous terms. Avoid new terms when `A` authentication versus `P` permissions would be unclear.

Add learned aliases/macros only when likely to repeat.
Prefer `Dict:` for active shared terms and `Dict+` for additions. Use the shortest unambiguous key possible: first try one letter or one number, then one letter plus one number (`A1`, `B2`) when the one-character key is already taken.

```text
Dict: S=state C=context D=action R=risk O=outcome N=no-go P=proof 1=failing-test-first
Dict+: A1=authentication bug fix
```

Persisted learned terms start as candidates and promote only through lifecycle rules. A term should not become part of active DSL unless it appears at least twice in a short window or the user explicitly approves it.

Only when the user explicitly requests learning and a sanitized transcript is available, run:

```bash
distill dsl learn-thread --stdin < transcript.txt
```

This analyzes repeated usage, rejects sensitive/noisy terms, asks the configured reviewer model for strict JSON, and persists only compact candidates.

## Tool Calls

Use context-mode for large tool output. Use `distill` only to compress the final user-visible result after the source evidence has been retained.

Never pipe tests, builds, lint, diffs, security checks, permission checks, infrastructure plans, or interactive/TUI commands through `distill` for PASS/FAIL or safety decisions.

CRITICAL: Your prompt to `distill` must be fully explicit. State exactly what you want to know and exactly what the output must contain. If you want only filenames, say `Return only the filenames.` If you want JSON, say `Return valid JSON only.` Do not ask vague questions.

Bad:

- `distill "Which files are shown?"`

Good:

- `distill "Which files are shown? Return only the filenames."`

Examples:

- Do not send test output to `distill`; use the original exit code and required raw failures.
- Do not send diffs to `distill` before review; inspect the actual diff, then compress only the final report.
- Do not use a `distill` summary as the safety judgment for an infrastructure plan.
- Do not use a `distill` summary as the primary vulnerability evidence.
- Use context-mode to filter large searches and return only the needed matches.
- Observe guaranteed-small listings directly instead of adding a second summarization step.

You may skip `distill` only in these cases:

- Exact uncompressed output is required.
- Using `distill` would break an interactive or TUI workflow.

CRITICAL: Wait for `distill` to finish before continuing.

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
