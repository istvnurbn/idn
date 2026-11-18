---
name: caveman-commit
description: >
  Write a Conventional Commits message compressed to intent only. Use every
  time the user asks for a commit or commit message(s), in any repo: "write a
  commit", "commit message", "commits for each item", /commit or
  /caveman-commit.
---

<!-- From skills/caveman-commit/SKILL.md in github.com/juliusbrussee/caveman
at a192894, Copyright 2026 Julius Brussee, Apache-2.0
(https://www.apache.org/licenses/LICENSE-2.0). Changed: wider description,
Delivery section. -->

Write commit messages terse and exact. Conventional Commits format. No fluff. Why over what.

## Rules

**Subject line:**
- `<type>(<scope>): <imperative summary>` — `<scope>` optional
- Types: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`, `style`, `revert`
- Imperative mood: "add", "fix", "remove" — not "added", "adds", "adding"
- ≤50 chars when possible, hard cap 72
- No trailing period
- Match project convention for capitalization after the colon

**Body (only if needed):**
- Skip entirely when subject is self-explanatory
- Add body only for: non-obvious *why*, breaking changes, migration notes, linked issues
- Wrap at 72 chars
- Bullets `-` not `*`
- Reference issues/PRs at end: `Closes #42`, `Refs #17`

**What NEVER goes in:**
- "This commit does X", "I", "we", "now", "currently" — the diff says what
- "As requested by..." — use Co-authored-by trailer
- "Generated with Claude Code" or any AI attribution — unless the user's own rule requires an `Assisted-by`/AI-attribution trailer, then add it as a trailer
- Emoji (unless project convention requires)
- Restating the file name when scope already says it

## Examples

Diff: new endpoint for user profile with body explaining the why
- ❌ "feat: add a new endpoint to get user profile information from the database"
- ✅
  ```
  feat(api): add GET /users/:id/profile

  Mobile client needs profile data without the full user payload
  to reduce LTE bandwidth on cold-launch screens.

  Closes #128
  ```

Diff: breaking API change
- ✅
  ```
  feat(api)!: rename /v1/orders to /v1/checkout

  BREAKING CHANGE: clients on /v1/orders must migrate to /v1/checkout
  before 2026-06-01. Old route returns 410 after that date.
  ```

## Auto-Clarity

Always include body for: breaking changes, security fixes, data migrations, anything reverting a prior commit. Never compress these into subject-only — future debuggers need the context.

## Boundaries

Only generates the commit message. Does not run `git commit`, does not stage files, does not amend. Output the message as a code block ready to paste. "stop caveman-commit" or "normal mode": revert to verbose commit style.

## Delivery

- Check `git log --oneline -20` first and match its types, scopes and casing.
- Claude Code's default `Co-Authored-By: Claude` trailer is AI attribution: leave it out.
- Put the message at the end of the reply, under its own `### Commit message` heading. Several commits or repos: one fenced block each, labeled with the repo.
- If the index holds staged changes that belong to another commit, add the command that commits only this one's paths: `git commit -- <paths>` (`git add` new files first).
