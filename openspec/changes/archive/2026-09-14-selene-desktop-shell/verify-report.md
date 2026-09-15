# Verify Report: Adopt Selene as the MoonArch Desktop Shell

## Result Contract

- **status:** PASS
- **executive_summary:** The desktop shell migration is complete and every repository gate passes: `go build`/`go vet`/`go test ./...` in `cli/`, the MoonArch theme palette contract, the 18-scenario selector suite, and the isolated Stow validation in Docker. The two new regression guards were confirmed to fail against the defects they cover, not merely to pass. The spec delta is archived into `openspec/specs/moonarch-theme-selector/spec.md`.
- **artifacts:**
  - `openspec/changes/selene-desktop-shell/verify-report.md`
  - Inputs read: `proposal.md`, `spec.md`, `design.md`, `tasks.md`, `openspec/config.yaml`, `openspec/specs/moonarch-theme-selector/spec.md`
- **next_recommended:** archive
- **risks:** The migrated bindings and autostart are adopted from a working live Hyprland session, so runtime behaviour is evidenced by that session rather than by a session started during this verification. Selene's own README still documents a rollback contract that lives in `MrUse77/Selene-Shell` and was not edited. `openspec/changes/consolidate-rofi-menu/` remains an unarchived, blocked predecessor change.
- **skill_resolution:** none (no skill paths were injected)

## Structured Status and Action Context

```yaml
changeName: selene-desktop-shell
artifactStore: openspec
changeRoot: /home/agustin/Dev/dotfiles/openspec/changes/selene-desktop-shell
artifacts:
  proposal: done
  design: done
  tasks: done
  specs: done
  verifyReport: done
nativeStatus: not queried (no review receipt requested for this change)
actionContext:
  mode: repo-local
  workspaceRoot: /home/agustin/Dev/dotfiles
  branch: feat/selene-desktop-shell
  allowedEditRoots:
    - /home/agustin/Dev/dotfiles
```

## Acceptance Criteria Coverage

| # | Criterion | Evidence | Result |
| --- | --- | --- | --- |
| 1 | Autostart launches `qs -c selene` and not `waybar`/`dunst` | Selector suite asserts `qs -c selene` presence and rejects a `& waybar &` or `& dunst &` sibling | PASS |
| 2 | Five bindings invoke Selene IPC | `hyprland.lua` contains `openApps`, `openWindows`, `openRun`, `togglePower`, `openThemes` on `Super+M`, `Super+Tab`, `Super+R`, `Super+Shift+X`, `Super+Shift+T` | PASS |
| 3 | No active config invokes the Rofi launcher except the selector's no-argument path | `waybar/config.jsonc` on-click handlers repointed; grep of `home/` leaves `theme-selector` line 125 and the launcher's own composition | PASS |
| 4 | `aur/quickshell-git` is pre-selected and listed ahead of the three fallbacks | `TestDefaultCategories_QuickshellLeadsDormantFallbacks` | PASS |
| 5 | Every menu package name exists in its group's catalog list | `TestDefaultCategories_PackageNamesMatchCatalogGroups` | PASS |
| 6 | Selene present as a submodule pinned to a published commit | `git submodule status` reports the pin without the uninitialised marker; `shell.qml` present so `qs -c selene` resolves | PASS |
| 7 | Spec names no retired picker and lists the real consumers | Delta archived into the main spec; two requirements modified | PASS |
| 8 | `test.sh`, selector suite and `go test ./...` pass | See Validation Commands | PASS |

## Task Completion

All nine tasks in `tasks.md` are complete. T1–T3 cover the installer package selection and its regression tests; T4–T7 cover the desktop configuration and the selector suite; T8–T9 cover the spec delta and its archival.

## Validation Commands

| Command | Result |
| --- | --- |
| `go build ./...` (in `cli/`) | PASS |
| `go vet ./...` (in `cli/`) | PASS |
| `go test ./...` (in `cli/`) | PASS — 7 packages ok, 2 with no test files |
| `bash tests/moonarch-theme-palette_test.sh` | PASS — 3 assertions |
| `bash tests/moonarch-theme-selector_test.sh` | PASS — 18 scenarios |
| `bash test.sh` | PASS — palette contract, Docker build, isolated Stow validation |
| `git submodule status` | PASS — `9a04360` initialised at `heads/main` |

### Negative validation

Both new guards were exercised against the defect they cover and then restored:

- Reintroducing `{Name: "waybar", …}` in the TUI menu makes `TestDefaultCategories_PackageNamesMatchCatalogGroups` fail with *"menu package \"waybar\" of group \"hyprland\" is absent from the catalog package list; deselecting it would still install nothing"*.
- Reintroducing `dunst` into the Hyprland autostart makes `tests/moonarch-theme-selector_test.sh` fail with *"Hyprland autostart starts a competing bar or notification daemon next to Selene"*.

## Strict TDD Compliance

`openspec/config.yaml` reports `strict_tdd: false` for the root project, which has no unit-testable code; its gate is the shell suite and `test.sh`. The `cli/` subproject has `strict_tdd: true`.

- The menu/catalog agreement test was written and confirmed failing against the stale `waybar` name before the fix was restored to green.
- The autostart exclusivity guard was confirmed failing against an injected `dunst` before being restored to green.
- Configuration-only changes (bindings, autostart, on-click handlers) have no unit-testable surface and are covered by the grep assertions in the selector suite.

## Review Workload / PR Boundary

The branch holds ~281 changed lines excluding the submodule tree, well under the 400-line budget, with no chaining required. Approximately 161 of the tracked lines are pre-existing uncommitted work on the same branch (`home/.local/bin/moonarch/theme-selector` and most of `tests/moonarch-theme-selector_test.sh`).

The submodule contributes a gitlink and three `.gitmodules` lines rather than a file tree. Because the pinned commit is part of the change's identity, advancing the pin is a separate reviewable change.

## Blockers

None for this change.

Two items are explicitly deferred and recorded rather than silently resolved:

1. **Selene's README rollback section** — it lives in `MrUse77/Selene-Shell`, which requires a commit in that repository and a pin bump here.
2. **`openspec/changes/consolidate-rofi-menu/`** — its `verify-report.md` records `status: FAIL` for two reasons: `tests/moonarch-theme-palette_test.sh` still required removed `wofi.css` assets, and Strict TDD Mode lacked a `TDD Cycle Evidence` table. Both blockers are resolved in the current tree, but that change was never archived, which is why `openspec/specs/moonarch-theme-selector/spec.md` still named Wofi until this change synced it. Archiving or abandoning that predecessor is separate work.
