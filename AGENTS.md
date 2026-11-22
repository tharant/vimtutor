# AGENTS.md — project rules for agents working in this repository

Applies to any AI agent (opencode, Claude, ...) or human making changes here.
Read together with the global rules in `~/.agents/` and `README.md`.

## Agent session log — refresh on EVERY commit (mandatory)

This repository preserves its full agentic development history: user
prompts, the model's reasoning, and every tool call with input/output.
The log lives in `agentlog/` and is committed to the repo.

### The rule

1. **Before every `git commit`, run:**

   ```sh
   scripts/export-agent-log
   ```

2. **If `agentlog/` changed, include it in the same commit**
   (`git add -A agentlog`). Prefer folding the log update into the commit
   it documents over a separate `chore:` commit.

3. A git **pre-commit hook does this automatically** (`core.hooksPath` is
   set to `.githooks/` in this repo). The hook refreshes the log, stages
   changes, and **fails the commit** if the opencode service is unreachable:
   fix the cause (`opencode service restart`) and retry. Never skip,
   disable, or bypass this hook; never use `--no-verify`.

### Working with the log

- **Never hand-edit anything under `agentlog/`.** It is generated data;
  regenerate with the script instead. Merge requests should not show
  manual patches to these files.
- Output is **incremental**: session `.md`/`.jsonl` files mostly grow by
  appending; expect exactly three kinds of *legitimate* rewrites: the
  JSONL meta line (live session totals: tokens, cost, message count),
  the final assistant message of an in-progress turn (rewritten when the
  turn completes), and `agentlog/README.md` (a regenerated index whose
  per-session stats update in place). Anything else — modified history,
  shrinking counts without a server-side compaction/revert, sessions
  disappearing — is a red flag worth investigating before committing.
- The `.jsonl` files are **full fidelity** (every tool input and byte of
  output); the `.md` files are the reviewable rendition, with tool outputs
  capped (`AGENTLOG_MD_MAX`, default 3000 chars; `0` disables).
- Sessions include subagent sessions (children), listed in the log index.
- The log is **verbatim** modulo redaction: personal/system strings are
  scrubbed at write time by the exporter through the **local, gitignored
  `.agentlog-redactions` map** (format and template in
  `.agentlog-redactions.example`), and token/cost usage stats are hidden by
  default (`AGENTLOG_HIDE_USAGE=0` to show). Never paste secrets, tokens or
  credentials into a session; do not commit the map -- if outputs reveal a
  new personal pattern, extend the map and regenerate.
- If a session was compacted or reverted in opencode, the regenerated log
  reflects the stored transcript state; stale artifacts for sessions that
  no longer exist server-side are removed by the script.

### How it works (for maintenance)

- Discovery: read-only query on opencode's SQLite store
  (`$XDG_DATA_HOME/opencode/opencode.db`, `session_v2` by directory
  prefix, BFS through subagent children); falls back to
  `opencode session list`.
- Content: `opencode session export <id>` (official CLI, talks to the
  running background service) — this is why the service must be up.
- Exit codes: `0` success, `4` opencode not installed in this environment
  (hook skips quietly), anything else is an error (hook fails the commit).
