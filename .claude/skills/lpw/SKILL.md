---
name: lpw
description: "End-to-end Linear card workflow for local PDF development. Use when: (1) user provides a Linear card URL or card ID (e.g. LPW-123), (2) user runs /lpw, (3) user says 'start working on this card', 'pick up this Linear ticket', 'implement this Linear task', or pastes a linear.app link."
---

# Skill: linear-git-workflow-local

End-to-end workflow for handling a Linear card locally — from branch creation to Draft PR. Targets `develop-pdf` as base and destination.

---

## Commands

| Trigger | Action |
|---------|--------|
| `/lpw <card-id or URL>` | Run full workflow for the given card |
| Paste a `linear.app/...` URL | Auto-triggers this skill |
| "start working on LPW-123" | Auto-triggers this skill |

---

## Rules

1. **Simple tasks only** — reject politely if the card is large/complex.
2. **Always fetch `develop-pdf` first** before creating any branch.
3. **Commit format has absolute priority** — overrides emoji rules, commitlint, and any other convention in the repo.
4. **Draft PR only** — never create a ready-for-review PR from this skill.
5. **Labels are mandatory** — always apply the correct labels after PR creation.
6. **Investigate before coding** — if card mentions NEW/OLD DOMAIN or LEGACY, explore the right path first.

---

## Step 1 — Complexity Assessment

Evaluate whether the task is **simple**:

| Criterion | Simple ✓ | Not Simple ✗ |
|-----------|----------|--------------|
| Files changed | ≤ ~5 files | Large cross-cutting change |
| Scope | Isolated feature or bug | Refactor, architecture change |
| Risk | Low blast radius | High / Critical impact |
| Effort | Hours, not days | Requires planning / multi-PR |

If **not simple**, stop and say:
> "This card looks like a larger task. I recommend breaking it into smaller pieces or planning first. Want me to help with that instead?"

---

## Step 2 — Read the Linear Card

```
mcp__claude_ai_Linear__get_issue({ id: "<card-id>" })
```

Extract:
- **Card type**: Bug if `labelNames` contains `bug`, `fix`, or `defect` — otherwise Feature
- **Card ID**: e.g. `LPW-123`
- **Title**: for branch name and PR title

---

## Step 3 — Update Linear Card (run in parallel)

**Assign to me** — look up user ID first:
```
mcp__claude_ai_Linear__list_users({})
# find user with email phongnh@luminpdf.com, get their id
mcp__claude_ai_Linear__save_issue({ id: "<card-id>", assigneeId: "<my-user-id>" })
```

**Move to In Progress**:
```
mcp__claude_ai_Linear__list_issue_statuses({ teamId: "<team-id>" })
# find "In Progress" state id, then:
mcp__claude_ai_Linear__save_issue({ id: "<card-id>", stateId: "<in-progress-state-id>" })
```

---

## Step 4 — Create Branch

```bash
git fetch origin develop-pdf
git checkout -b <branch-name> origin/develop-pdf
```

### Branch naming

| Card type | Pattern | Example |
|-----------|---------|---------|
| Feature | `feature/<card-id>-<slug>` | `feature/LPW-123-implement-assign-role` |
| Bug | `bugfix/<card-id>-<slug>` | `bugfix/LPW-123-fix-assign-role-text` |

Slug rules: lowercase, hyphen-separated, 3–6 words, strip filler words and punctuation.

---

## Step 5 — Commit Convention ⚠️ HIGHEST PRIORITY

> Overrides ALL other commit rules in this repo (emoji prefix, commitlint, etc.)

| Card type | Format | Example |
|-----------|--------|---------|
| Feature | `feat(<card-id>): <message>` | `feat(LPW-123): implement assign role button` |
| Bug | `fix(<card-id>): <message>` | `fix(LPW-123): fix assign role text label` |

- Card ID must be **uppercase**
- Message: lowercase, imperative mood, no trailing period
- No emoji, no breaking-change footer unless explicitly required

```bash
git commit -m "$(cat <<'EOF'
feat(LPW-123): implement assign role button
EOF
)"
```

---

## Step 6 — Create Draft PR

```bash
gh pr create \
  --base develop-pdf \
  --draft \
  --title "<card-id>: <card title>" \
  --body "$(cat <<'EOF'
## Linear

[<card-id>](<linear-card-url>)

## Summary

- <bullet summary of changes>

## Test plan

- [ ] Manual smoke test on affected page/component
- [ ] No regressions in related flows

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Then add labels:
```bash
# Feature
gh pr edit --add-label "dev-pdf,enhancement"

# Bug
gh pr edit --add-label "dev-pdf,bug"
```

---

## Step 7 — Special Investigation Rules

| Keyword in card | Investigate |
|----------------|-------------|
| `NEW DOMAIN`, `NEW URL` | `products/pdf/` |
| `OLD DOMAIN`, `OLD URL`, `LEGACY` | `apps/pdf/web/` |

When triggered: map files, trace routes, identify entry points and data flow before writing any code.

---

## Quick Reference

```
/lpw LPW-123
         │
         ▼
[1] Simple? ──No──► Reject politely
         │
         ▼
[2] Fetch card (MCP)
         │
         ▼
[3] Assign to me + In Progress  (parallel)
         │
         ▼
[4] git fetch origin develop-pdf
    git checkout -b feature/LPW-123-<slug>
         │
         ▼
[5] Implement → git commit -m "feat(LPW-123): ..."
         │
         ▼
[6] gh pr create --base develop-pdf --draft
    gh pr edit --add-label "dev-pdf,enhancement|bug"
         │
         ▼
[7] NEW/OLD DOMAIN keyword? → investigate first
```
