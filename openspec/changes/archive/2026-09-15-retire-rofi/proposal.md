# Retire Rofi

## Why

Selene covers every role Rofi had, so keeping Rofi installed and configured only leaves the repository asserting things that are no longer true.

Rofi's `config.rasi` enabled five modes, and Selene exposes an IPC method for each:

| Rofi mode | Rofi label | Selene |
| --- | --- | --- |
| `drun` | Apps | `openApps` |
| `window` | Active Apps | `openWindows` |
| `run` | Run | `openRun` |
| `calc` | Calculator | `calc`, reachable from the launcher with the `=` prefix |
| `powermenu` | Power | `togglePower` |
| no arguments (`-dmenu`) | — | `openThemes` |

The labels match because Selene's launcher was designed as the replacement. Three further pieces of Rofi were already unreachable: `scripts/powermenu` and `scripts/launch-powermenu` since Selene took `Super+Shift+X`, and `scripts/launch`'s theme-compositing wrapper since nothing needs to composite a Rof theme fragment any more.

Two things kept Rofi nominally alive, and neither survives scrutiny:

- `theme-selector`'s no-argument path opened a Rofi `-dmenu` picker. That is a picker, not a capability: Selene already enumerates candidates through `theme-selector --list` and commits through `theme-selector --apply`, so the path becomes a delegation.
- The palette contract asserted that `rofi/scripts/launch` composed the active theme fragment. That was coverage of a file nothing invoked.

The installer still lists `rofi` in the `hyprland` group and pre-selects it, so a fresh install also pulled a launcher nothing starts.

## What Changes

- **Changed**: `theme-selector`'s no-argument path delegates to `qs -c selene ipc call selene openThemes` instead of piping candidate IDs into a Rofi `-dmenu`. It captures no selection and exits non-zero naming `--list` and `--apply` when Quickshell is unavailable.
- **Changed**: `theme-selector`'s `required_files` drops `rofi.rasi`, so the required fragments become `hyprland.conf hyprland.lua waybar.css ghostty.conf`. Bundles still carrying a stale `rofi.rasi` remain valid, because extra files were always allowed.
- **Removed**: `home/.config/rofi/` — `config.rasi`, `theme.rasi`, `scripts/launch`, `scripts/launch-powermenu`, `scripts/powermenu`.
- **Removed**: the 12 `rofi.rasi` fragments under `home/.local/share/moonarch/themes/`.
- **Removed**: `rofi` from the `hyprland` package group and from the TUI menu.
- **Changed**: the palette contract drops every Rofi assertion and keeps every remaining one.
- **Changed**: the selector suite replaces its `ROFI_*` fixtures and cancellation scenario with delegation scenarios, and its retired-tool guard now rejects a `rofi` reference under `home/` alongside `eww` and `dunst`.
- **Changed**: `README.md`, `CONTRIBUTING.md` and both issue templates stop offering Rofi.

## Scope

### In scope

- Move the selector's interactive path to Selene and relax the fragment requirement it no longer needs.
- Delete Rofi's configuration and the theme fragments only it consumed.
- Stop installing, offering and documenting Rofi.
- Sync the two capability requirements that named Rofi.

### Out of scope

- **The 13 `home/.local/share/moonarch/themes/*/waybar.css` fragments.** They stay: Selene derives its tokens from them.
- **The Waybar reload branch in `theme-selector`.** It stays best-effort and inert.
- **The `--list`, `--apply` and bare positional modes.** They must keep working without Quickshell, which is what makes the selector usable from Selene and from a terminal.
- `Temas/*/paleta.txt` and `hyde_theme_palettes.txt`, which are historical source-palette dumps whose Rofi section label is descriptive text.
- `cli/pkg/installer/packages.go`, the dead legacy package list.
- **Dunst.** Its package remains installed and pre-selected although its configuration was retired earlier. That is a separate inconsistency, recorded here rather than fixed, because it reverses a decision archived in `retire-eww-dunst-wlogout` and deserves its own change.

## Affected areas

| Area | Expected change |
| --- | --- |
| `home/.local/bin/moonarch/theme-selector` | Interactive path delegates to Selene; `rofi.rasi` leaves `required_files`. |
| `home/.config/rofi/` | Deleted — 5 tracked files. |
| `home/.local/share/moonarch/themes/*/rofi.rasi` | Deleted — 12 fragments. |
| `cli/pkg/installer/catalog.go`, `ui/menu/data.go` | `rofi` dropped from the group and the menu. |
| `cli/pkg/installer/catalog_menu_test.go` | Fallback list narrows to `dunst`. |
| `tests/moonarch-theme-palette_test.sh` | Rofi assertions and mappings removed. |
| `tests/moonarch-theme-selector_test.sh` | Rofi fixtures replaced by delegation scenarios; guard widened. |
| `README.md`, `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/*` | Rofi no longer offered or documented as the picker. |
| `openspec/specs/moonarch-theme-selector/spec.md` | Two requirements synced. |

## Benefits

- Every desktop role has exactly one owner, and no configuration outlives the tool it configured.
- The installer stops pulling a launcher that nothing starts.
- The selector's interactive path has one owner instead of two implementations of the same picker.
- The capability spec stops naming a tool that no longer exists.

## Trade-offs

- The selector's no-argument path now depends on a running Selene, where the Rofi picker did not. It fails loudly rather than silently, but it is a real narrowing: `--list`, `--apply` and the positional form remain the Quickshell-independent routes.
- The theme bundle contract loses a fragment. Bundles from older releases keep validating, but a bundle written to the old contract now carries a file nothing reads.
- Rollback for Rofi becomes Git-only, since neither its configuration nor its package entry remains.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Removing a fragment Selene actually reads. | Selene reads `waybar.css` and `ghostty.conf` only; `Services/Theme.qml` binds to `current/waybar.css`, and the palette contract still asserts every `waybar.css` mapping. |
| A picker path that returns success without opening anything, which no assertion can distinguish from working. | The suite asserts the delegation invokes `qs -c selene ipc call selene openThemes` and that it fails with a naming message when Quickshell is unavailable. |
| Invalidating bundles from older releases. | Relaxing `required_files` is a relaxation: `validate_bundle` iterates only the required list, so extra files including a stale `rofi.rasi` stay valid. The suite keeps writing a stale `rofi.rasi` into its fixtures to hold that property. |
| Losing the guard on the Hyprland bindings or autostart while editing the selector suite. | Those assertions stay byte-identical; the guard is only widened. |
| A menu entry surviving without its catalog entry. | `TestDefaultCategories_PackageNamesMatchCatalogGroups` fails when a menu name is absent from its group. |

## Rollback

Revert through Git. Unlike the earlier retirements this one is configuration-only in the tree, but the fragment deletion and the selector's argument surface are coupled, so a partial revert would leave the selector requiring a fragment no bundle provides.

## Success criteria

- No `rofi.rasi` fragment exists under any theme bundle, and `theme-selector` does not require one.
- A bundle carrying a stale `rofi.rasi` still validates.
- `theme-selector` with no arguments invokes `qs -c selene ipc call selene openThemes`, captures no selection, and fails with a message naming `--list` and `--apply` when Quickshell is unavailable.
- `--list`, `--apply <id>` and the bare positional form work without Quickshell.
- The 13 `waybar.css` bundle fragments still exist.
- `rofi` appears in neither the `hyprland` catalog group nor the TUI menu.
- No configuration, documentation or issue template offers Rofi.
- `bash test.sh`, `bash tests/moonarch-theme-selector_test.sh` and `go test ./...` pass.
