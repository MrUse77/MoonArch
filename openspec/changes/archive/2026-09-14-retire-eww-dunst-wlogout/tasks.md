# Tasks: Retire the Eww and Dunst widget stack

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~1499 (1481 deletions + ~18 authored lines) |
| 400-line budget risk | High by line count, Low by review burden |
| Chained PRs recommended | No |
| Suggested split | Single PR with size exception |
| Delivery strategy | single-pr (requires `size:exception`) |
| Chain strategy | size-exception |

```text
Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: High
```

**Rationale for the size exception:** 1481 of the ~1499 changed lines are deletions of one retired tool's configuration, widget definitions, assets and helper scripts. Nothing in that span requires reasoning about behaviour; a reviewer confirms the tool is gone and that nothing reaches it. The authored surface is ~18 lines: four references repointed to Selene, one guard widened, and twelve lines of installer entries removed.

Splitting the deletion away from the guard and the installer entries would create an intermediate state in which the tree still references a deleted tool, which is worse than one large, coherent deletion.

**Branch-level note:** this change stacks on `selene-desktop-shell` (~281 lines) on the same branch, so the branch total is ~1780 changed lines. If the two are delivered as one PR, the same exception has to cover both; delivering them as two PRs keeps the first under budget and isolates the deletion.

---

## Dependency Graph

```text
T1 (repoint the three Eww references) ──→ T3 (delete the configuration)
T2 (widen the retired-reference guard) ──┘
T4 (drop the installer entries) ── independent
T5 (verify) ← T1..T4
```

## Task List

- [x] **T1: Repoint the three Eww references to Selene** — 4 lines changed
- **Files:** `home/.config/hypr/hyprland.lua`, `home/.config/waybar/config.jsonc`
- **Description:** Replace the `eww daemon` autostart entry with nothing, point `Super+N` at `seleneIpc .. "toggleDashboard"`, and point Waybar's `custom/notification` on-click at `qs -c selene ipc call selene toggleDashboard`.
- **Acceptance criteria:** No tracked configuration reaches an Eww script.
- **Verification:** `grep -rEw '(eww|dunst)' home/` returns nothing.

- [x] **T2: Widen the retired-reference guard** — ~6 lines changed
- **File:** `tests/moonarch-theme-selector_test.sh`
- **Description:** Extend the guard that rejects a reintroduced Eww reference so it covers `dunst` as well, and replace the brittle `& tool &` autostart pattern with a check over the whole `hl.on("hyprland.start")` block, because the pattern missed commands carrying arguments such as `eww daemon`.
- **Acceptance criteria:** A reintroduced `eww` or `dunst` reference fails the suite.
- **Verification:** Injecting `eww daemon` into the autostart, then a file naming `eww`, then a file naming `dunst`, each fails the suite; all restored afterwards. The three autostart variants (`eww daemon`, `dunst`, `waybar`) each trip the guard.

- [x] **T3: Delete the Eww and Dunst configuration** — 1481 lines deleted, 13 files
- **Files:** `home/.config/eww/`, `home/.config/dunst/`
- **Description:** Delete both directories, including `eww.yuck`, `eww.scss`, the four helper scripts, three PNG assets and `dunstrc`.
- **Acceptance criteria:** Neither directory exists; thirteen paths are reported as deletions.
- **Verification:** `ls` confirms absence; `git status --short` reports thirteen deletions.

- [x] **T4: Drop the retired packages from the installer** — 12 lines changed
- **Files:** `cli/pkg/installer/catalog.go`, `cli/pkg/installer/ui/menu/data.go`
- **Description:** Remove `aur/eww` and `aur/wlogout` from the `theming` group and from the Theming & Appearance category, and drop the category description's mention of widgets.
- **Acceptance criteria:** Neither name appears in the catalog or the menu, and the menu/catalog agreement test still passes.
- **Verification:** `gofmt -l .`, `go build ./...`, `go vet ./...`, `go test ./...`.

- [x] **T5: Run the full gate** — verification
- **Description:** Run the palette contract, the selector suite, the Docker Stow validation and the Go suite.
- **Acceptance criteria:** All green.
- **Verification:** Recorded in `verify-report.md`.

---

## Execution Notes

**Ordering constraint:** T1 must complete before T3. Deleting the configuration while tracked bindings still point into it would ship a desktop whose keybinding launches a missing script.

**Strict TDD considerations:** the root project has `strict_tdd: false` and no unit-testable code; the guard added in T2 is its regression protection. The `cli/` subproject has `strict_tdd: true`, and the existing menu/catalog agreement test covers the installer change without modification.
