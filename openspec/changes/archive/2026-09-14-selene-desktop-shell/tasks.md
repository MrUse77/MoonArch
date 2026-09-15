# Tasks: Adopt Selene as the MoonArch Desktop Shell

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~281 (additions + deletions), excluding the submodule tree |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | single-pr |
| Chain strategy | n/a |

```text
Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: n/a
400-line budget risk: Low
```

**Breakdown:** ~34 lines across `hyprland.lua`, the Waybar config, `catalog.go`, the TUI menu data and `.gitmodules`; 75 lines of new regression test; ~10 lines in the selector test suite; plus change artifacts and a spec delta. Approximately 161 of the tracked lines are pre-existing uncommitted work in progress on the same branch and were not authored by this change.

**Submodule note:** `home/.config/quickshell/selene` adds a gitlink and three `.gitmodules` lines, not a file tree. The pinned commit is part of the snapshot identity.

---

## Dependency Graph

```text
T1 (catalog group) ──→ T2 (TUI menu entry) ──→ T3 (regression tests)
T4 (Hyprland vars, bindings, autostart) ──→ T7 (selector binding assertion + autostart guard)
T5 (Waybar dormant clicks)   T6 (Selene submodule)
T8 (spec delta) ──→ T9 (archive and sync)
```

## Task List

### Batch 1: Installer Package Selection

- [x] **T1: Add Quickshell to the Hyprland package group** — 1 line changed
- **File:** `cli/pkg/installer/catalog.go`
- **Description:** Add `"aur/quickshell-git"` to the `plan.GroupHyprland` package list, positioned before `aur/waybar-git`, `rofi` and `dunst`.
- **Acceptance criteria:** Quickshell is installable through the `hyprland` group.
- **Verification:** `go build ./...`; the new menu/catalog agreement test asserts the group installs the name the menu offers.

- [x] **T2: Lead the Hyprland TUI category with Quickshell** — ~5 lines changed
- **File:** `cli/pkg/installer/ui/menu/data.go`
- **Description:** Add `aur/quickshell-git` as a pre-selected package of the Hyprland category, listed ahead of the Waybar, Rofi and Dunst fallbacks. Rename the `waybar` entry to `aur/waybar-git` so exclusion matches the catalog verbatim. Keep Waybar, Rofi and Dunst pre-selected as dormant fallbacks.
- **Acceptance criteria:** Quickshell is pre-selected and listed ahead of the three fallbacks; deselecting Waybar actually prevents its install.
- **Verification:** `TestDefaultCategories_QuickshellLeadsDormantFallbacks` and `TestDefaultCategories_PackageNamesMatchCatalogGroups`.

- [x] **T3: Add package-selection regression tests** — 75 lines added
- **File:** `cli/pkg/installer/catalog_menu_test.go` (new)
- **Description:** Assert that every menu package name of a group appears in that group's catalog list, skipping `hypr-plugins` which installs through `hyprpm`; and that Quickshell is pre-selected and listed before the three dormant fallbacks, which stay pre-selected.
- **Acceptance criteria:** A menu/catalog name mismatch fails the suite.
- **Verification:** Reintroducing the stale `waybar` name makes `TestDefaultCategories_PackageNamesMatchCatalogGroups` fail with the mismatch message; restored afterwards.

### Batch 2: Desktop Shell Migration

- [x] **T4: Repoint Hyprland bindings to Selene** — 20 lines changed
- **File:** `home/.config/hypr/hyprland.lua`
- **Description:** Replace the five Rofi command variables with one `local seleneIpc = "qs -c selene ipc call selene "` prefix. Repoint `Super+M`, `Super+Tab`, `Super+R`, `Super+Shift+X` and `Super+Shift+T` to `openApps`, `openWindows`, `openRun`, `togglePower` and `openThemes`. Drop `waybar` and `dunst` from the autostart while keeping `eww daemon`.
- **Acceptance criteria:** The autostart launches Selene only, among bar and notification tools; all five bindings invoke Selene IPC.
- **Verification:** The selector suite asserts the `Super+Shift+T` binding and autostart exclusivity.

- [x] **T5: Repoint Waybar's dormant on-click handlers** — 4 lines changed
- **File:** `home/.config/waybar/config.jsonc`
- **Description:** Change `custom/power` to `qs -c selene ipc call selene togglePower` and `custom/launcher` to `qs -c selene ipc call selene openApps`.
- **Acceptance criteria:** No active configuration invokes the Rofi launcher scripts except the selector's no-argument path.
- **Verification:** Grep for `rofi/scripts/launch` outside the selector returns only the launcher's own theme composition.

- [x] **T6: Vendor Selene as a submodule** — 3 lines added to `.gitmodules` plus a gitlink
- **Files:** `.gitmodules`, `home/.config/quickshell/selene`
- **Description:** Add `MrUse77/Selene-Shell` as a submodule pinned to a published commit, using the HTTPS URL so the installer's existing `git submodule update --init --recursive` action works without SSH credentials.
- **Acceptance criteria:** `git submodule status` reports the submodule initialised at the pinned commit; `home/.config/quickshell/selene/shell.qml` exists so `qs -c selene` resolves.
- **Verification:** `git submodule status` shows the pin without the uninitialised marker; `bash test.sh` passes the isolated Stow validation with the submodule present.

- [x] **T7: Update the selector suite for the new bindings** — ~10 lines changed
- **File:** `tests/moonarch-theme-selector_test.sh`
- **Description:** Update the `Super+Shift+T` assertion to the Selene mechanism and add a guard that the autostart launches `qs -c selene` and does not start `waybar` or `dunst` beside it.
- **Acceptance criteria:** The suite fails if a competing bar or notification daemon returns to the autostart.
- **Verification:** Re-injecting `dunst` makes the guard fail with its message; restored afterwards.

### Batch 3: Spec Synchronisation

- [x] **T8: Sync the MoonArch theme selector capability** — spec delta
- **File:** `openspec/changes/selene-desktop-shell/specs/moonarch-theme-selector/spec.md`
- **Description:** Modify `Name-Only Validated Atomic Switching` to name Selene as the interactive picker, state that the picker lists through `--list` and applies through `--apply`, require that those invocations do not depend on Selene, and list the consumers that reload. Modify `Bounded Runtime Scope` to replace Wofi with Rofi and to record that Selene consumes the Waybar fragment without needing its own.
- **Acceptance criteria:** The spec names no retired picker and matches the reloading consumers in the implementation.
- **Verification:** `openspec validate selene-desktop-shell --strict` before archiving.

- [x] **T9: Archive the change and sync the main spec** — admin
- **Description:** Run `openspec archive selene-desktop-shell` so the delta merges into `openspec/specs/moonarch-theme-selector/spec.md`, then confirm the resulting spec no longer names Wofi in its requirements and patch the Purpose line if the archive does not rewrite it.
- **Acceptance criteria:** The archived change is complete and the main spec matches the implementation.
- **Verification:** `openspec validate --archived`; grep of `openspec/specs/moonarch-theme-selector/spec.md` for retired tool names.

---

## Batch Grouping for sdd-apply

### Batch 1: Installer Package Selection

**Tasks:** T1, T2, T3
**Estimated lines:** ~81 additions
**Rationale:** These are independent of the desktop configuration and are covered by Go unit tests, so they can be reviewed and reverted on their own.

### Batch 2: Desktop Shell Migration

**Tasks:** T4, T5, T6, T7
**Estimated lines:** ~37 changed + submodule
**Rationale:** These must land together: repointing the bindings without the autostart would leave two bars, and the submodule must exist before `qs -c selene` can resolve on a fresh install.

### Batch 3: Spec Synchronisation

**Tasks:** T8, T9
**Estimated lines:** change artifacts only
**Rationale:** Documentation must follow the verified implementation, and archiving merges the delta into the main spec.

---

## Execution Notes

**Strict TDD considerations:**

- The root project has `strict_tdd: false` and no unit-testable code; the selector suite and `test.sh` are its integration gate.
- `cli/` has `strict_tdd: true`; the two package-selection tests were written and confirmed to fail against the pre-fix name before passing.
- Shell assertions were validated by re-injecting the failure they guard against, and restored afterwards.

**Ordering constraint:** the spec delta must not be archived before the bindings and the selector behaviour are in place, because the delta describes reloading consumers that only exist after T4.
