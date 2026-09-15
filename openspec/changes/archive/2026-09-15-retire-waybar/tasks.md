# Tasks: Retire the Waybar configuration and package

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~533 (440 deletions + ~93 authored lines, mostly deletions) |
| 400-line budget risk | High by line count, Low by review burden |
| Chained PRs recommended | No |
| Suggested split | Single PR with size exception |
| Delivery strategy | single-pr (requires `size:exception`) |
| Chain strategy | size-exception |

```text
Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: High
```

**Rationale for the size exception:** 528 of the ~533 changed lines are deletions — Waybar's three configuration files and the 88 lines of palette-test coverage that read them. The authored surface is about five lines. Splitting the deletion from the test that reads the deleted file would create an intermediate state with a red suite.

**Branch-level note:** this change stacks on the two already archived in this branch. Counting only this slice, the branch's cumulative total is what decides the PR boundary, and a reviewer should see this as one deletion of one tool.

---

## Dependency Graph

```text
T1 (remove the installer entry, both sides) ──┐
T2 (delete the configuration directory) ──────┼─→ T4 (narrow the palette contract)
T3 (drop the selector stylesheet assertion) ──┘
T4 ──→ T5 (full gate)
```

## Task List

- [x] **T1: Drop the Waybar package from the installer** — 3 lines changed
- **Files:** `cli/pkg/installer/catalog.go`, `cli/pkg/installer/ui/menu/data.go`
- **Description:** Remove `aur/waybar-git` from the `hyprland` group and from the Hyprland category. Both sides change together because exclusion matches names verbatim.
- **Acceptance criteria:** The name appears in neither side, and `TestDefaultCategories_PackageNamesMatchCatalogGroups` still passes.
- **Verification:** `go test ./...` in `cli/`.

- [x] **T2: Delete Waybar's configuration directory** — 437 lines deleted, 3 files
- **File:** `home/.config/waybar/`
- **Description:** Delete `config.jsonc`, `style.css` and `colors.css`. The directory was swept first: nothing outside it references any of its files, and `colors.css` was already orphaned inside it.
- **Acceptance criteria:** The directory does not exist and its files are reported as deletions.
- **Verification:** `git status --short` reports three deletions.

- [x] **T3: Remove the selector suite's stylesheet assertion** — 1 line changed
- **File:** `tests/moonarch-theme-selector_test.sh`
- **Description:** Remove the single assertion that `@import`ed the theme fragment from `home/.config/waybar/style.css`.
- **Acceptance criteria:** Exactly one assertion removed; the retired-tool guard, the Selene binding assertion, the autostart guard and all 18 scenarios are byte-identical.
- **Verification:** `git diff --stat` reports a one-line deletion; the suite passes.

- [x] **T4: Narrow the palette contract to the bundle fragments** — 88 lines changed
- **File:** `tests/moonarch-theme-palette_test.sh`
- **Description:** Remove the stylesheet variable, its awk helper, the fixed-colour check and the 13 rule-alias checks that all read `home/.config/waybar/style.css`. Keep every assertion that reads a theme bundle's `waybar.css`, including the four aliases and all 11 semantic mappings.
- **Acceptance criteria:** The suite passes and still validates the four bundle aliases and the 11 mappings.
- **Verification:** `bash tests/moonarch-theme-palette_test.sh` passes with the bundle assertions present.

- [x] **T5: Keep the documented stack accurate** — ~5 lines changed
- **Files:** `README.md`, `CONTRIBUTING.md`
- **Description:** The stack note no longer lists Waybar among the installed-and-configured fallbacks, the directory tree drops `waybar/`, and the commit-scope row goes.
- **Acceptance criteria:** No document claims Waybar is installed or configured.
- **Verification:** Grep the two files for `waybar`.

- [x] **T6: Run the full gate** — verification
- **Description:** Palette contract, selector contract, Docker Stow validation and the Go suite.
- **Acceptance criteria:** All green.
- **Verification:** Recorded in `verify-report.md`.

---

## Execution Notes

**Ordering constraint:** T1 must not leave a menu entry without its catalog entry, and T3 and T4 must land with or after T2, because both read the file it deletes.

**Strict TDD considerations:** the root project has `strict_tdd: false` and no unit-testable code; the palette and selector suites are its gate. The `cli/` subproject has `strict_tdd: true`, and the existing menu/catalog agreement test covers T1 unmodified — Waybar left both sides, so the two still agree.

**Coverage note:** T4 removes real assertions. They described a stylesheet against fixed colour literals and theme aliases, so their subject is gone; the bundle-level assertions they were adjacent to are the ones that still have a subject, and they are preserved.
