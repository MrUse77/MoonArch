# Tasks: Drop Dunst from the installer

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~90 (roughly 40 authored, 50 replaced) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Chain strategy | n/a |

```text
Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: n/a
400-line budget risk: Low
```

This is the only slice in the branch under the 400-line budget, and it is the only one that replaces a test rather than deleting configuration.

---

## Dependency Graph

```text
T1 (replacement test, written first) ──→ T2 (catalog) ──→ T3 (menu)
T2, T3 ──→ T4 (documentation)
T4 ──→ T5 (gate)
```

## Task List

- [x] **T1: Replace the fallback test** — ~50 lines changed
- **File:** `cli/pkg/installer/catalog_menu_test.go`
- **Description:** Replace `TestDefaultCategories_QuickshellLeadsDormantFallbacks` with `TestDefaultCategories_QuickshellReplacesRetiredTools`, asserting that Quickshell is offered and pre-selected and that none of the five retired packages is offered in any category.
- **Acceptance criteria:** The test fails while Dunst is still offered.
- **Verification:** RED run reports `dunst must not be offered: Selene replaces it and its configuration was removed`.

- [x] **T2: Drop Dunst from the package group** — 1 line changed
- **File:** `cli/pkg/installer/catalog.go`
- **Description:** Remove `"dunst"` from `plan.GroupHyprland`.
- **Acceptance criteria:** The group no longer installs it.
- **Verification:** `go test ./...` in `cli/` passes, including the replacement test.

- [x] **T3: Drop the menu entry** — 1 line changed
- **File:** `cli/pkg/installer/ui/menu/data.go`
- **Description:** Remove the matching entry so both sides agree.
- **Acceptance criteria:** `TestDefaultCategories_PackageNamesMatchCatalogGroups` still passes.
- **Verification:** `go test ./...` in `cli/`.

- [x] **T4: Keep the documented stack accurate** — ~8 lines changed
- **Files:** `README.md`, `openspec/config.yaml`
- **Description:** Record that the retired tools' packages are no longer installed, naming Dunst among them.
- **Acceptance criteria:** No document claims those packages are still installed.
- **Verification:** Grep the two files for `dunst`.

- [x] **T5: Run the full gate** — verification
- **Description:** `gofmt`, `go build`, `go vet`, `go test` in `cli/`, plus `bash test.sh` to confirm the shell guards still pass.
- **Acceptance criteria:** All green.
- **Verification:** Recorded in `verify-report.md`.

---

## Execution Notes

**Ordering constraint:** T1 before T2, so the RED state is observable rather than assumed.

**Strict TDD considerations:** the `cli/` subproject has `strict_tdd: true`, and this is the one slice in the branch with a genuine RED-then-GREEN cycle: the replacement test was written first and failed on Dunst before the catalog changed.

**Guard note:** neither shell guard is narrowed. `dunst` stays in the autostart guard and in the `home/` reference guard, because both now protect against reintroduction of a package that is no longer installed anywhere.
