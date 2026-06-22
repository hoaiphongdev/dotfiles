# Code Refactor Best Practices (Local)

Triggered by `/refactor-code` followed by a PR link or specific code/file path.

## Core Rule (Priority #1)

**NEVER refactor in a way that changes or breaks existing logic or behavior.**
Safety and correctness are more important than any other rule. If a refactoring step would alter runtime behavior, skip it and note why.

---

## Workflow

1. **Identify the target**: Parse the PR link or file path from the user's command.
2. **If PR link**: Fetch the diff with `gh pr diff <number>`, identify all changed files.
3. **If file/directory**: Read the specified files directly.
4. **Analyze** each file against the refactoring rules below, in order.
5. **Identify the project logger**: Before touching any logging, search the codebase for the logger in use (e.g. `winston`, `pino`, `loglevel`, a custom `logger` import). Use that logger consistently.
6. **Apply refactorings** file by file, verifying after each change that no behavior is altered.
7. **Run lint**: After all changes, run the project linter on every modified file and fix all errors/warnings.

---

## Refactoring Rules (Apply in Order)

### 1. Separation of Concerns

- Extract types, interfaces, and enums into dedicated files (`types.ts`, `interfaces.ts`, or colocated `*.types.ts`).
- Extract pure utility functions into a `utils/` folder or `*.util.ts` files.
- Extract constants (magic numbers, config values, string literals) into `constants.ts` or colocated `*.constants.ts`.
- Keep each file focused on a single responsibility.

### 2. Function Quality

- Every function should be **under 30-40 lines**. Break larger functions into smaller, well-named helpers.
- **No inline functions in JSX.** Never write `onClick={() => handleSomething()}` or `onClick={() => { ... }}`.
  - Declare a named handler: `const handleClick = () => { ... }` then reference it: `onClick={handleClick}`.
  - This applies to all JSX event handlers and render callbacks.
- Function names must clearly describe what the function does.

### 3. Control Flow

- Minimize nested `if` statements. Use early returns and guard clauses.
- Prefer flat structure over deeply indented blocks.
- Replace `if/else` chains with early-exit patterns where possible.

### 4. Variable Declarations

- Use `const` by default. Only use `let` when reassignment is genuinely required.
- Never use `var`.

### 5. React Hooks Cleanup

- Remove `useCallback` unless it is passed as a prop to a memoized child or listed as a dependency of another hook where identity matters.
- Remove `useMemo` unless the computation is measurably expensive or the value is used in a dependency array where referential stability matters.
- If removal doesn't change behavior, remove it.

### 6. Error Handling & Logging

- **No silent `try-catch` blocks.** Every `catch` must either handle the error or re-throw it.
- **No `console.log`, `console.error`, `console.warn`, or `console.info`.** Replace all with the project's logger.
- Detection steps:
  1. Search for existing logger imports in the file and its neighbors (`import.*logger`, `import.*log`).
  2. Search the project for logger configuration (`winston`, `pino`, `loglevel`, custom `createLogger`, etc.).
  3. Use the discovered logger consistently: `logger.error()`, `logger.warn()`, `logger.info()`.
- If a silent catch is intentional, add a comment explaining why and log at an appropriate level (e.g. `logger.debug()`).

### 7. Comments

- Remove all comments that restate what the code does.
- Remove commented-out code.
- Keep only:
  - `TODO:` comments with actionable context.
  - Comments explaining **why** something non-obvious is done.

### 8. Code Style & Best Practices

- Place `return` statements and `if` conditions on their own lines for readability.
- **Avoid `any` type.** Replace with proper types wherever possible. Only use `any` (with an `eslint-disable` comment) when fixing it would require major breaking changes.
- After all refactoring, run ESLint/Biome on every changed file and fix all errors and warnings.
- Follow the project's existing code style and conventions.

---

## Safety Checklist (Before Completing)

- [ ] No runtime behavior has changed.
- [ ] All existing tests still pass.
- [ ] No new `any` types introduced without justification.
- [ ] No `console.*` calls remain.
- [ ] Linter passes on all modified files.
- [ ] All extracted files are properly imported where needed.
