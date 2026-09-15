# Retire the Eww and Dunst widget stack

## Why

`selene-desktop-shell` moved the default desktop to Selene and deliberately kept Waybar, Rofi, Eww and Dunst installed and configured as dormant fallbacks, so a session could roll back without a package install. That rollback path is now the only thing keeping two of those tools in the tree.

After that change, `home/.config/eww/` and `home/.config/dunst/dunstrc` are unreferenced:

- Nothing in `home/` mentions `dunst` at all, and it left the autostart in this branch.
- Nothing in `home/` mentions `eww` either. The three references it had — the `eww daemon` autostart entry, the `Super+N` binding and Waybar's `custom/notification` click — were repointed to Selene in this branch.

Eww's slice is covered by Selene's dashboard (`toggleDashboard`) and Dunst's by Selene's freedesktop notification server. Keeping the configuration means carrying twelve Eww files and a Dunst configuration that no tracked configuration can reach, plus the `aur/eww` and `aur/wlogout` entries in the installer, which would install a widget host and a session menu that nothing launches.

This change reverses the dormant-fallback decision for these two tools only. Waybar and Rofi stay, because their configuration is still reachable and load-bearing.

## What Changes

- **Removed**: `home/.config/eww/` and `home/.config/dunst/` — 13 tracked files.
- **Removed**: `aur/eww` and `aur/wlogout` from the `theming` package group in `cli/pkg/installer/catalog.go`.
- **Removed**: the `aur/eww` and `aur/wlogout` entries from the Theming & Appearance category in `cli/pkg/installer/ui/menu/data.go`.
- **Changed**: the selector suite's Eww guard no longer needs to exclude `home/.config/eww/`, because the directory is gone.

## Scope

### In scope

- Delete the Eww configuration, widget definitions, styles and helper scripts.
- Delete the Dunst configuration.
- Stop offering `aur/eww` and `aur/wlogout` in the installer, in both the catalog and the TUI menu.
- Keep the `home/.config/hypr/hyprland.lua` bindings and the Waybar on-click handlers pointing at Selene, which this branch already did.

### Out of scope

- Waybar and Rofi removal. Waybar's configuration is asserted by the theme palette contract and Rofi's launcher composes the current theme fragment, so both need their own change and their own test updates.
- The 13 `rofi.rasi` and 13 `waybar.css` fragments inside the theme bundles. `waybar.css` is read by Selene and must stay; `rofi.rasi` is only dead once Rofi leaves.
- `cli/pkg/installer/packages.go`. It retains a legacy package list with no callers that still names `aur/eww` and `aur/wlogout`; correcting or deleting that file is separate work.
- Any change to Selene itself.

## Affected areas

| Area | Expected change |
| --- | --- |
| `home/.config/eww/` | Deleted — 12 tracked files including `eww.yuck`, `eww.scss` and `scripts/`. |
| `home/.config/dunst/` | Deleted — `dunstrc`. |
| `cli/pkg/installer/catalog.go` | `aur/eww` and `aur/wlogout` dropped from the `theming` group. |
| `cli/pkg/installer/ui/menu/data.go` | The matching menu entries dropped. |
| `tests/moonarch-theme-selector_test.sh` | Eww guard widened to all of `home/`. |

## Benefits

- Twelve Eww files and a Dunst configuration that no tracked file can reach stop being carried and reviewed.
- The installer stops offering two packages whose tools nothing launches.
- Retirement becomes an explicit transaction removal, so an existing installation has the targets backed up and inventoried before deletion.

## Trade-offs

- The dormant-fallback set shrinks from four tools to two. Reverting Eww or Dunst now requires restoring configuration from Git rather than flipping a binding.
- Notification behaviour after the change depends entirely on Selene; there is no second notification daemon installed.
- The `theming` group loses two of its six packages, so the category's purpose narrows to GTK/Qt theming and the prompt.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Removing the Dunst package leaves a session with no notification daemon if Selene fails to start. | Already true in this branch: Dunst left the autostart and Selene owns the bus. The removal changes installability, not runtime behaviour. |
| An existing installation keeps orphaned Eww and Dunst files after upgrade. | `installation-transaction` requires installed targets omitted from desired to be explicit removals, backed up and inventoried before deletion, skipped when already absent, and restored if the transaction fails. |
| A menu entry survives without its catalog entry, making the checkbox decorative. | `TestDefaultCategories_PackageNamesMatchCatalogGroups` fails when a menu name is absent from its group. |
| A tracked configuration reintroduces an Eww reference after the directory is gone. | `tests/moonarch-theme-selector_test.sh` fails if `eww` appears anywhere under `home/`. |
| Waybar or Rofi break as a side effect. | Both are untouched by this change and remain covered by the palette contract and the selector suite. |

## Rollback

Revert the change through Git to restore both configuration directories and the two installer entries. No package operation is required to reinstall Eww or Dunst beyond the installer entry that the revert restores.

## Success criteria

- `home/.config/eww/` and `home/.config/dunst/` no longer exist and are absent from the tracked tree.
- No file under `home/` references `eww` or `dunst`.
- `aur/eww` and `aur/wlogout` appear in neither the `theming` catalog group nor the TUI menu.
- `Super+N` and Waybar's `custom/notification` click open Selene's dashboard.
- `bash test.sh`, `bash tests/moonarch-theme-selector_test.sh` and `go test ./...` pass.
