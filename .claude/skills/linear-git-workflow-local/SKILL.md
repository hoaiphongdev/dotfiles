# Skill: linear-git-workflow-local

## Description

A strict, end-to-end workflow for handling Linear card links locally. When given a Linear card URL, this skill orchestrates everything from branch creation through Draft PR, enforcing consistent naming conventions and commit formats.

**Scope**: LOCAL use only — targets `develop-pdf` as the base and destination branch.

---

## Activation

Triggered when the user provides a Linear card URL, e.g.:
- `https://linear.app/luminpdf/issue/LPW-123/some-card-title`
- Or a bare card ID like `LPW-123`

---

## Step 1 — Complexity Assessment

Before doing anything, evaluate whether the task is **simple**:

| Criterion | Simple | Not Simple |
|-----------|--------|------------|
| Files changed | ≤ ~5 files | Large cross-cutting change |
| Scope | Isolated feature or bug | Refactor, architecture change |
| Risk | Low blast radius | High / Critical impact |
| Effort | Hours, not days | Requires planning / multi-PR |

- **If simple** → proceed with this workflow.
- **If not simple** → stop and respond:
  > "This card appears to be a larger task. I recommend breaking it into smaller pieces or creating a plan first. Would you like me to help with that instead?"

---

## Step 2 — Read the Linear Card

Use the Linear MCP to fetch the card details:

```
mcp__claude_ai_Linear__get_issue({ id: "<card-id>" })
```

Extract:
- **Card type**: Feature (`feature/`) vs. Bug (`bugfix/`)
  - Determine from the card's `labelNames` or `type` field. Labels containing `bug`, `fix`, or `defect` → Bug. Otherwise → Feature.
- **Card ID**: e.g. `LPW-123`
- **Title**: used to derive the branch suffix

---

## Step 3 — Update Linear Card

Run both in parallel:

1. **Assign** to me:
   ```
   mcp__claude_ai_Linear__save_issue({ id: "<card-id>", assigneeId: "<my-user-id>" })
   ```

2. **Move to In Progress**:
   ```
   mcp__claude_ai_Linear__get_issue_status({ teamId: "<team-id>" })
   # Find the "In Progress" status ID, then:
   mcp__claude_ai_Linear__save_issue({ id: "<card-id>", stateId: "<in-progress-state-id>" })
   ```

---

## Step 4 — Create Branch

### Fetch latest `develop-pdf` first

```bash
git fetch origin develop-pdf
git checkout -b <branch-name> origin/develop-pdf
```

### Branch naming rules

| Card type | Pattern | Example |
|-----------|---------|---------|
| Feature | `feature/<card-id>-<short-kebab-case-description>` | `feature/LPW-123-implement-assign-role` |
| Bug | `bugfix/<card-id>-<short-kebab-case-description>` | `bugfix/LPW-123-update-assign-role-text` |

**Rules for the description suffix**:
- Derive from the card title — lowercase, words joined with `-`
- Strip special characters, punctuation, and filler words (`a`, `the`, `for`, etc.)
- Keep it short: 3–6 words max

---

## Step 5 — Commit Convention (HIGHEST PRIORITY)

> These commit rules override ALL other commit conventions in this repo (emoji rules, commitlint, etc.).

| Card type | Format | Example |
|-----------|--------|---------|
| Feature | `feat(<card-id>): <message>` | `feat(LPW-123): implement assign role button` |
| Bug | `fix(<card-id>): <message>` | `fix(LPW-123): fix assign role text label` |

**Rules**:
- Use the exact card ID (uppercase) as the scope, e.g. `feat(LPW-123): ...`
- Message is lowercase, imperative mood, no period at end
- No emoji prefix, no breaking-change footer unless required
- One logical change per commit

**Full git commit command**:
```bash
git commit -m "$(cat <<'EOF'
feat(LPW-123): implement assign role button
EOF
)"
```

---

## Step 6 — Create Draft Pull Request

Target branch: **`develop-pdf`**

```bash
gh pr create \
  --base develop-pdf \
  --draft \
  --title "<card-id>: <card title>" \
  --body "$(cat <<'EOF'
## Linear

[<card-id>](<linear-card-url>)

## Summary

- <bullet point summary of changes>

## Test plan

- [ ] Manual smoke test on affected page/component
- [ ] No regressions in related flows

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Labels

| Card type | Labels to add |
|-----------|--------------|
| Feature | `dev-pdf`, `enhancement` |
| Bug | `dev-pdf`, `bug` |

Apply labels after PR creation:
```bash
gh pr edit --add-label "dev-pdf,enhancement"   # Feature
gh pr edit --add-label "dev-pdf,bug"            # Bug
```

---

## Step 7 — Special Investigation Rules

Check the card title and description for these keywords before diving into code:

| Keyword found | Deep-investigate path |
|--------------|----------------------|
| `NEW DOMAIN`, `NEW URL` | `products/pdf/` |
| `OLD DOMAIN`, `OLD URL`, `LEGACY` | `apps/pdf/web/` |

When triggered, run a thorough exploration of the relevant path before writing any code:
- Map relevant files, components, and routes
- Identify entry points and data flow
- Note any existing tests

---

## Quick Reference

```
Linear card given
       │
       ▼
[1] Assess complexity ──► Too complex? → Reject politely
       │
       ▼
[2] Fetch card via MCP
       │
       ▼
[3] Assign to me + move to In Progress (parallel)
       │
       ▼
[4] git fetch origin develop-pdf
    git checkout -b feature/<id>-<slug>  OR  bugfix/<id>-<slug>
       │
       ▼
[5] Implement changes
    git commit -m "feat(<id>): ..."  OR  "fix(<id>): ..."
       │
       ▼
[6] gh pr create --base develop-pdf --draft
    gh pr edit --add-label "dev-pdf,enhancement|bug"
       │
       ▼
[7] Check for NEW DOMAIN / OLD DOMAIN keywords → investigate accordingly
```

---

## My Identity (Linear)

To resolve "assign to me", look up the current user via:
```
mcp__claude_ai_Linear__get_user({ id: "me" })
```
or use the email `phongnh@luminpdf.com` to find the user ID from:
```
mcp__claude_ai_Linear__list_users({})
```
