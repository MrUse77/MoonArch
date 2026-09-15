# Drop Dunst from the installer

## Why

`retire-eww-dunst-wlogout` deleted Dunst's configuration but deliberately kept its package installed and pre-selected, on the grounds that the documented rollback turned it back on without a package install. That reasoning has since collapsed, in the same branch:

- Waybar and Rofi were both fully retired afterwards, configuration and package alike, so Dunst is the last package kept for a rollback path no longer offered for its siblings.
- Dunst's configuration no longer exists, so a fresh install pulls a notification daemon with nothing to read: it would run with upstream defaults if anything started it, which nothing does.

What remains is an installer that pre-selects a package whose configuration was removed, justified by a policy that no longer has any other member. Selene owns `org.freedesktop.Notifications`, so nothing here restores a fallback; it only removes an inconsistency.

## What Changes

- **Removed**: `dunst` from the `hyprland` package group in `cli/pkg/installer/catalog.go`.
- **Removed**: the matching entry from the Hyprland category in `cli/pkg/installer/ui/menu/data.go`.
- **Changed**: `cli/pkg/installer/catalog_menu_test.go` — the dormant-fallback test becomes `TestDefaultCategories_QuickshellReplacesRetiredTools`, which asserts that Quickshell is offered and pre-selected and that none of `aur/waybar-git`, `rofi`, `dunst`, `aur/eww` or `aur/wlogout` is offered in any category.
- **Changed**: `README.md` and `openspec/config.yaml` record that these packages are no longer installed.

## Scope

### In scope

- Stop offering, pre-selecting and installing Dunst.
- Replace a fallback test whose subject no longer exists with one that locks the retirements in place.
- Keep the documented stack accurate.

### Out of scope

- **The autostart and reference guards.** `tests/moonarch-theme-selector_test.sh` still rejects `dunst` in the Hyprland autostart block and any `eww`/`dunst` reference under `home/`. Those stay: they now protect against reintroduction rather than describing current state.
- `cli/pkg/installer/packages.go`, the dead legacy list that still names `waybar`, `wofi`, `dunst`, `aur/eww` and `aur/wlogout`. It has no callers.
- The 13 `waybar.css` bundle fragments and the Waybar reload branch in `theme-selector`.
- Any further fallback policy decision. This change removes the last member of a policy that had already lost its point, rather than replacing it with a new one.

## Affected areas

| Area | Expected change |
| --- | --- |
| `cli/pkg/installer/catalog.go` | `dunst` dropped from `plan.GroupHyprland`. |
| `cli/pkg/installer/ui/menu/data.go` | Matching menu entry dropped. |
| `cli/pkg/installer/catalog_menu_test.go` | The fallback test is replaced by a retirement lock. |
| `README.md`, `openspec/config.yaml` | No package is described as still installed. |

## Benefits

- The installer stops pre-selecting a package with no configuration and no launcher.
- The test suite asserts the retirements instead of a policy with one remaining member and no rationale.
- The documented stack matches what the installer actually does.

## Trade-offs

- Rolling back to Dunst now needs a package install as well as a configuration restore from Git. That is already true of Waybar and Rofi, so this makes the four consistent rather than introducing a new asymmetry.
- The `hyprland` group loses its last non-Hyprland desktop tool, leaving it a Hyprland-and-portals group. That is the accurate description of what it now installs.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| A menu entry surviving without its catalog entry. | `TestDefaultCategories_PackageNamesMatchCatalogGroups` fails when a menu name is absent from its group. |
| Losing the protection against reintroducing Dunst. | The autostart guard and the `home/` reference guard both still name `dunst`; this change narrows neither. |
| Quietly widening the change into a new fallback policy. | Out of scope and stated as such: this removes the last member of a policy that had already lost its point. |
| An existing installation keeping an orphaned Dunst package. | Removing a package is not a managed target. The installer never uninstalls, and this change does not start: `paru -Rns dunst` stays a user decision. |

## Rollback

Revert through Git to restore both installer entries. No package operation is required beyond the entry the revert restores.

## Success criteria

- `dunst` appears in neither the `hyprland` catalog group nor the TUI menu.
- No category offers `aur/waybar-git`, `rofi`, `dunst`, `aur/eww` or `aur/wlogout`.
- `aur/quickshell-git` stays offered and pre-selected.
- `go test ./...` passes in `cli/`.
- No document claims those packages are still installed.
- The autostart guard and the `home/` reference guard still name `dunst`.
