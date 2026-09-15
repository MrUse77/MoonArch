# Design: Adopt Selene as the MoonArch Desktop Shell

## Decision summary

| Decision | Choice | Rationale |
| --- | --- | --- |
| Shell | Selene, launched as `qs -c selene` | One process covers bar, notifications, launcher, OSD, session menu and dashboard. |
| Retired stack | Installed and configured, but dormant | Rollback stays a binding change instead of a package install. |
| Autostart | `hyprpolkitagent & eww daemon & hyprctl setcursor … & qs -c selene & hyprsunset` | Waybar and Dunst stop owning the bar and the notification bus; Eww still backs `Super+N`. |
| Binding mechanism | One IPC prefix variable | The five bindings keep their structure and change only the command they expand to. |
| Theme picker | Selene's `openThemes` | The desktop's theme entry point stops being a launcher menu. |
| Vendoring | Git submodule | Selene is an independent project with its own history, tests and spec tree. |
| Runtime fallback | None | A `command -v qs` probe detects installation, not a broken shell, and `&` cannot be safely combined with `&&`/`||` in one exec string. |

## Architecture and data flow

```text
Hyprland session
├── /usr/lib/hyprpolkitagent/hyprpolkitagent
├── eww daemon ─────────────────────→ Super+N control center
├── qs -c selene ─┬─ Bar (per monitor)          ← theme tokens from waybar.css
│                 ├─ Launcher (Apps/Windows/Run/Themes/calc)
│                 ├─ Notifications (org.freedesktop.Notifications) ← single owner
│                 ├─ Osd, PowerMenu, Dashboard
│                 └─ IpcHandler target "selene"
└── hyprsunset

Hyprland bindings ──→ qs -c selene ipc call selene <method>
Selene Themes mode ──→ moonarch/theme-selector --list
                   └──→ moonarch/theme-selector --apply <id>
```

## Shell ownership and autostart

The autostart keeps its single `hl.exec_cmd` chain. Waybar and Dunst are removed from it; Eww is retained because the control center binding is unchanged in this slice.

Exclusivity matters for exactly one pair: `org.freedesktop.Notifications` is a non-queueable well-known bus name, so a second registrant fails. Selene implements the freedesktop server, therefore Dunst is never autostarted. Waybar and Selene can coexist as Wayland clients, but starting both would render two bars, so Waybar is removed as well.

`tests/moonarch-theme-selector_test.sh` asserts that the autostart launches `qs -c selene` and that it does not start `waybar` or `dunst` beside it. Eww is intentionally outside that guard.

## Hyprland integration

Five Rofi command variables collapse into one prefix:

```lua
local seleneIpc = "qs -c selene ipc call selene "
```

| Binding | Before | After |
| --- | --- | --- |
| `Super+M` | `menu` (Rofi `drun` with mode switching) | `seleneIpc .. "openApps"` |
| `Super+Tab` | `windowMenu` (Rofi `-show window`) | `seleneIpc .. "openWindows"` |
| `Super+R` | `runMenu` (Rofi `-show run`) | `seleneIpc .. "openRun"` |
| `Super+Shift+X` | `powerMenu` (Rofi powermenu script) | `seleneIpc .. "togglePower"` |
| `Super+Shift+T` | `~/.local/bin/moonarch/theme-selector` | `seleneIpc .. "openThemes"` |

The trailing space in the prefix is significant: every binding concatenates a method name onto it.

The theme fragment of the active bundle is loaded at `hyprland.lua` top level with `io.open`, `pcall(dofile, theme_path)` and `hl.config(theme_config)`. It contributes a configuration table, so a bundle cannot redefine bindings.

## Theme selector integration

The selector keeps three entry points and they keep their precedence:

1. `--list` prints validated bundle IDs and touches nothing else.
2. `--apply <id>` and a bare positional `<id>` validate atomically and reload consumers.
3. No arguments opens the Rofi dmenu picker.

`Super+Shift+T` no longer reaches the no-argument path: it opens Selene's Themes mode, which calls `--list` to enumerate and `--apply` to commit. The no-argument Rofi path therefore becomes unreachable from tracked configuration while still functioning if invoked directly, which keeps the Rofi dependency honest rather than dead.

Reload is unchanged: `hyprctl reload` is mandatory, Waybar receives `SIGUSR2` when running, and `qs -c selene ipc call selene themeReload` is best-effort for both the success and rollback paths. Neither `--list` nor `--apply` requires Selene to be running.

## Waybar dormant integration

Waybar is not autostarted, but its configuration is corrected rather than left stale: `custom/power` and `custom/launcher` are repointed to `qs -c selene ipc call selene togglePower` and `openApps`. If a session reactivates Waybar, its controls drive the same overlays as the bindings instead of reviving the Rofi path as a side effect.

`style.css` is deliberately not touched. The repository's copy is newer than the deployed one and uses the shared theme aliases that `tests/moonarch-theme-palette_test.sh` asserts.

## Installer package selection

`aur/quickshell-git` is added to the `hyprland` group of `collectPackages` and as a pre-selected entry of the Hyprland category in the TUI menu, listed ahead of the Waybar, Rofi and Dunst fallbacks. Waybar, Rofi, Eww and Dunst stay pre-selected so the documented rollback needs no install.

The AUR package declares `Provides: quickshell` and `Conflicts: quickshell`, so the official `quickshell` package must never be listed alongside it.

Menu entries and catalog entries are matched verbatim, because exclusion is a string comparison: `menu.ExcludedPackages` returns the unticked entries' `Name` values and `collectPackages` filters group packages by exact match. The `waybar` menu entry did not match the `aur/waybar-git` catalog entry, so unticking Waybar installed it anyway. Two regression tests close that class of defect:

- `TestDefaultCategories_PackageNamesMatchCatalogGroups` asserts every menu name of a group exists in that group's catalog list, skipping `hypr-plugins` because those install through `hyprpm`.
- `TestDefaultCategories_QuickshellLeadsDormantFallbacks` asserts Quickshell is pre-selected and listed first, and that Waybar, Rofi and Dunst stay pre-selected as dormant fallbacks.

## Selene vendoring

Selene is added as a submodule at `home/.config/quickshell/selene`, pinned to a published commit on `MrUse77/Selene-Shell`.

Integration is automatic:

- `installDiscoverer.Discover` enumerates `home/.config/*` with `os.ReadDir` and creates a copy target per entry.
- `scripts/stow-dev.sh` stows the whole `home/` tree as one package.
- `home/.stow-local-ignore` already excludes `.git`, `.gitignore` and `.gitmodules`.

The submodule name must equal its path. Renaming the entry desynchronises `.git/modules/<name>` and makes `git submodule status` report the submodule as uninitialised.

Because Quickshell resolves `-c selene` to `~/.config/quickshell/selene`, the config directory name is part of the contract.

## Verification plan

### Static checks

- `go build ./...`, `go vet ./...` in `cli/`.
- `go test ./...` in `cli/`, including the two package-selection regression tests.
- Confirm the autostart string and the five bindings by grep, and confirm no active configuration still invokes the Rofi launcher scripts other than the selector's no-argument path.

### Behavioral checks

- `bash tests/moonarch-theme-selector_test.sh` — selector scenarios plus the consumer-binding section.
- `bash test.sh` — theme palette contract, then the isolated Stow validation in Docker.
- Re-inject `dunst` into the autostart and confirm the exclusivity guard fails, then restore.

## Rollout and rollback

Rollout is a configuration and installer change; no user-data migration is required. Users who run the installer additionally receive the submodule through the existing `git submodule update --init --recursive` action.

Rollback is `git revert` plus a Hyprland reload, because the retired packages remain installed and pre-selected.

## Risks and constraints

- Selene depends on an AUR package; a failed build leaves no bar. The fallback is manual and documented.
- The dormant stack keeps configuration that no longer runs, which is intentional but must not be mistaken for dead weight.
- Selene's own README documents a rollback contract that this change only partly preserves; it lives in another repository and is not edited here.
- `cli/pkg/installer/packages.go` retains a legacy package list with no callers that still names Waybar, Wofi and Dunst. Correcting or deleting it is separate work.
