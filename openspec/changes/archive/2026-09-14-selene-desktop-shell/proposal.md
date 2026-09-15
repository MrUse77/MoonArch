# Adopt Selene as the MoonArch desktop shell

## Intent

Make Selene — a Quickshell/QML shell — the default MoonArch desktop, and sync the capability spec that still describes the retired picker. The Waybar/Rofi/Dunst stack stays installed and configured but dormant, so a session can fall back without installing anything.

## Problem statement

The MoonArch desktop is assembled from four independent tools, each owning one slice of the shell:

- **Waybar** draws the bar.
- **Dunst** owns `org.freedesktop.Notifications`.
- **Rofi** provides application, window, run and power menus.
- **Eww** provides the `Super+N` control center.

Selene implements all four slices in one process: a bar with tray, workspaces, window title, clock, battery, audio, media and update widgets; a unified launcher with Apps, Active Apps, Run and Themes modes plus a calculator; a freedesktop notification server with history; a volume OSD; a session menu with confirmation for destructive actions; and a dashboard that replaces the Eww control center.

Three concrete problems follow from the split:

1. **The installer cannot offer the shell the desktop actually runs.** `aur/quickshell-git` appears in no group of `cli/pkg/installer/catalog.go`, and the TUI menu in `cli/pkg/installer/ui/menu/data.go` lists neither Quickshell nor the shell it supersedes as a first-class choice.
2. **The interactive theme picker is the last launcher-shaped dependency of the theme selector.** `theme-selector` with no arguments pipes candidate bundle IDs into `~/.config/rofi/scripts/launch -dmenu`, so the desktop's theme entry point is a Rofi menu even though the shell is no longer Rofi.
3. **The capability spec is wrong twice over.** `openspec/specs/moonarch-theme-selector/spec.md` still names Wofi as the selector and lists "Hyprland, Waybar, Wofi, and Ghostty" as the supported consumers. That drift predates this change: `openspec/changes/consolidate-rofi-menu/` contains proposal, spec, design, tasks and verify-report but no spec delta, so the Rofi migration never reached the spec. This change adds the Selene picker on top of that unfixed drift.

## Proposed solution

Adopt `qs -c selene` as the desktop shell and demote the retired stack to dormant fallbacks.

| Role | Before | After |
| --- | --- | --- |
| Bar | `waybar` (autostarted) | `qs -c selene` |
| Notifications | `dunst` (autostarted) | Selene's freedesktop server |
| Apps / Windows / Run | Rofi menus | `selene openApps` / `openWindows` / `openRun` |
| Power menu | Rofi powermenu | `selene togglePower` |
| Theme picker entry point | `theme-selector` + Rofi dmenu | `selene openThemes` |
| Control center | Eww (`Super+N`) | unchanged; Eww still autostarts |

The installer gains `aur/quickshell-git` as the first desktop-shell entry of the `hyprland` group, listed ahead of the Waybar, Rofi and Dunst fallbacks and pre-selected. Waybar, Rofi, Eww and Dunst remain pre-selected so the documented rollback needs no package install; nothing autostarts them, so no second `org.freedesktop.Notifications` owner appears.

Selene is vendored as a git submodule at `home/.config/quickshell/selene` rather than copied, matching the repository's existing submodule pattern. `installDiscoverer` discovers `home/.config/*` by directory scan and `scripts/stow-dev.sh` stows all of `home/`, so no enumeration needs updating.

## Scope

### In scope

- Add `aur/quickshell-git` to the `hyprland` group in `cli/pkg/installer/catalog.go`.
- Add `aur/quickshell-git` as a pre-selected entry of the Hyprland category in `cli/pkg/installer/ui/menu/data.go`, listed ahead of the Waybar, Rofi and Dunst fallbacks, and correct the `waybar` entry to the `aur/waybar-git` name the catalog installs.
- Add `cli/pkg/installer/catalog_menu_test.go`, asserting that every menu package name exists in its catalog group and that Quickshell leads the pre-selected fallbacks.
- Replace the five Rofi command variables in `home/.config/hypr/hyprland.lua` with one Selene IPC prefix, repoint `Super+M`, `Super+Tab`, `Super+R`, `Super+Shift+X` and `Super+Shift+T`, and drop Waybar and Dunst from the autostart.
- Repoint the `custom/power` and `custom/launcher` Waybar on-click handlers to Selene IPC.
- Vendor Selene as a submodule pinned to a published commit.
- Extend `tests/moonarch-theme-selector_test.sh` with the new selector binding and a guard that the autostart does not start Waybar or Dunst beside Selene.
- Sync the two `moonarch-theme-selector` requirements that name the retired picker.

### Out of scope

- Deleting `home/.config/{rofi,waybar,eww,dunst}/` or the `rofi.rasi` fragment of any theme bundle. The Rofi launcher still composes the current theme fragment and the selector still consumes it.
- Removing `rofi.rasi` from the theme bundle contract, which would invalidate every existing bundle.
- Removing Waybar, Rofi, Eww, Dunst or `wlogout` from the installer catalog. They stay installable.
- Changing the `theme-selector` no-argument picker. Nothing invokes the selector without arguments once `Super+Shift+T` opens Selene's picker, so the Rofi path stays inert rather than removed.
- Replacing the Eww control center with Selene's dashboard. `Super+N` is unchanged.
- Editing Selene's own README, which lives in `MrUse77/Selene-Shell`.
- Automatic runtime fallback when `qs` is missing. Mixing `&` with `&&`/`||` in a single Hyprland exec string is unsafe, and an installed-but-broken Selene is undetectable by a `command -v` probe anyway.

## Affected areas

| Area | Expected change |
| --- | --- |
| `home/.config/hypr/hyprland.lua` | Selene IPC prefix replaces the Rofi variables; five bindings repointed; autostart drops Waybar and Dunst. |
| `home/.config/waybar/config.jsonc` | Two on-click handlers repointed to Selene IPC. |
| `home/.config/quickshell/selene` | New submodule pinned to a published Selene commit. |
| `.gitmodules` | One submodule entry. |
| `cli/pkg/installer/catalog.go` | `aur/quickshell-git` added to the `hyprland` group. |
| `cli/pkg/installer/ui/menu/data.go` | Quickshell added first and pre-selected; Waybar entry renamed to its catalog identity. |
| `cli/pkg/installer/catalog_menu_test.go` | New regression coverage for menu/catalog name agreement. |
| `tests/moonarch-theme-selector_test.sh` | Selector binding assertion updated; autostart exclusivity guard added. |
| `openspec/specs/moonarch-theme-selector/spec.md` | Two requirements synced to the Selene picker and the real consumers. |

## Benefits

- One process owns the bar, notifications, launcher, OSD, session menu and dashboard, replacing four.
- `org.freedesktop.Notifications` has a single owner by construction, and a guard keeps it that way.
- The installer can install the shell the desktop runs, and it leads the menu it defaults to.
- The inactive stack stays installable and configured, so rollback is a binding change rather than a package install.
- Menu package names and catalog package names can no longer drift silently.

## Trade-offs

- The desktop shell now depends on an AUR package. If the build fails, no bar appears; the fallback is manual by design.
- `theme-selector` keeps a Rofi dependency in its no-argument path even though nothing calls it that way.
- Rofi, Waybar, Eww and Dunst remain installed and carry configuration that no longer runs.
- The repository now carries a submodule whose own README documents a rollback contract that only partly holds after this change.
- `cli/pkg/installer/packages.go` keeps a dead legacy package list that still names Waybar, Wofi and Dunst; it has no callers and is not corrected here.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Dunst and Selene both claim `org.freedesktop.Notifications`, breaking notifications silently. | Dunst is never autostarted; `tests/moonarch-theme-selector_test.sh` fails if the autostart reintroduces it beside Selene. |
| A menu entry names a package the catalog spells differently, so deselecting it installs nothing. | `TestDefaultCategories_PackageNamesMatchCatalogGroups` asserts every menu name exists in its group's catalog list. |
| `quickshell-git` conflicts with the official `quickshell` package. | Only `aur/quickshell-git` is listed; the AUR package provides and conflicts with `quickshell`. |
| A theme bundle could override the migrated bindings. | The bundle fragment is loaded with `pcall(dofile, theme_path)` and applied with `hl.config(theme_config)`, so it contributes configuration data, not executable bindings. |
| The submodule pin drifts from Selene's `main`. | The pin is an explicit commit; advancing it is a separate, reviewable change. |
| Removing the Rofi bindings makes the stowed Rofi configuration unused but still present. | Documented as out of scope; the configuration remains valid for the selector and for rollback. |

## Rollback

Configuration-only, through Git:

1. Revert this change to restore the Rofi command variables, the four Rofi launcher bindings, `Super+Shift+T` pointing at the selector script, and the Waybar on-click handlers.
2. Restore `waybar & eww daemon & dunst` in the Hyprland autostart, or run those commands manually for the current session.
3. Reload Hyprland or restart the session.

No package install is required because Waybar, Rofi, Eww and Dunst stay installed and pre-selected in the installer. Selene can additionally be stopped with `qs -c selene ipc call selene ...` or by removing it from the autostart.

## Success criteria

- The Hyprland autostart launches `qs -c selene` and does not start `waybar` or `dunst`.
- `Super+M`, `Super+Tab`, `Super+R`, `Super+Shift+X` and `Super+Shift+T` invoke Selene IPC methods `openApps`, `openWindows`, `openRun`, `togglePower` and `openThemes`.
- No active configuration under `home/` invokes `~/.config/rofi/scripts/launch` except the `theme-selector` no-argument path and the launcher's own theme-fragment composition.
- `aur/quickshell-git` is pre-selected and listed ahead of the Waybar, Rofi and Dunst fallbacks in the installable Hyprland category.
- Every package name in the TUI menu exists in its group's catalog package list.
- Selene is present at `home/.config/quickshell/selene` as a submodule pinned to a published commit.
- `openspec/specs/moonarch-theme-selector/spec.md` names no retired picker and lists the consumers the implementation actually reloads.
- `bash test.sh`, `bash tests/moonarch-theme-selector_test.sh` and `go test ./...` pass.
