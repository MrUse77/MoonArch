# Retire the Waybar configuration and package

## Why

Waybar was left installed and configured as a dormant fallback when Selene became the desktop shell. That fallback is now unreachable rather than dormant:

- Hyprland autostarts `qs -c selene` and nothing else.
- Every Waybar on-click handler in the tree — the power, notification and launcher modules — was repointed to Selene IPC, so the configuration drives Selene overlays rather than its own behaviour.
- The installer still offers `aur/waybar-git` and pre-selects it, so a fresh install pulls a status bar that nothing starts.

Three files of bar configuration therefore remain unreachable, and one of the 13 theme bundles' `waybar.css` fragments is the only part of this that is still load-bearing.

This supersedes the dormant-fallback policy for Waybar specifically. Rofi and Dunst keep theirs.

## What Changes

- **Removed**: `home/.config/waybar/` — `config.jsonc`, `style.css` and `colors.css`, 437 lines across 3 files.
- **Removed**: `aur/waybar-git` from the `hyprland` package group in `cli/pkg/installer/catalog.go` and from the Hyprland category in `cli/pkg/installer/ui/menu/data.go`.
- **Changed**: `cli/pkg/installer/catalog_menu_test.go` — the dormant-fallback test expects `rofi` and `dunst` only.
- **Changed**: `tests/moonarch-theme-palette_test.sh` — the 88 lines of coverage that read `home/.config/waybar/style.css` are gone.
- **Changed**: `tests/moonarch-theme-selector_test.sh` — one assertion removed, the `@import` check on the deleted stylesheet.
- **Changed**: `README.md` and `CONTRIBUTING.md` — the stack note, the directory tree and the commit-scope row no longer claim Waybar is configured.

## Scope

### In scope

- Delete Waybar's own configuration directory.
- Stop offering and pre-selecting the Waybar package.
- Remove the test coverage that read the deleted stylesheet.
- Keep the documented stack accurate.

### Out of scope

- **The 13 `home/.local/share/moonarch/themes/*/waybar.css` fragments.** They stay. Selene derives its colour tokens from them through its own `Services/Theme.qml`, so they are load-bearing for the running shell despite the name.
- **The Waybar reload branch in `theme-selector`** (`pgrep -x waybar` / `pkill -SIGUSR2 waybar`). It is best-effort and a no-op when Waybar is absent, the spec names Waybar as a reloaded consumer, and removing it would require a capability delta for no runtime benefit.
- Rofi retirement. Its configuration is still reachable: `theme-selector` opens its no-argument picker through `rofi/scripts/launch`, and the palette contract asserts that launcher composes the theme fragment.
- `cli/pkg/installer/packages.go`, which retains a dead legacy package list naming Waybar, Wofi and Dunst. It has no callers.
- Test fixtures elsewhere that use a Waybar path as sample data.

## Affected areas

| Area | Expected change |
| --- | --- |
| `home/.config/waybar/` | Deleted — 3 tracked files. |
| `cli/pkg/installer/catalog.go` | `aur/waybar-git` dropped from `plan.GroupHyprland`. |
| `cli/pkg/installer/ui/menu/data.go` | Matching menu entry dropped. |
| `cli/pkg/installer/catalog_menu_test.go` | Fallback list narrowed to `rofi` and `dunst`. |
| `tests/moonarch-theme-palette_test.sh` | Stylesheet-only coverage removed; every bundle-fragment assertion kept. |
| `tests/moonarch-theme-selector_test.sh` | One assertion removed. |
| `README.md`, `CONTRIBUTING.md` | Waybar no longer described as installed and configured. |

## Benefits

- Three files of unreachable bar configuration stop being carried and reviewed.
- A fresh install no longer pulls a status bar that nothing starts.
- The palette contract keeps asserting exactly the part of the Waybar story that still matters: the bundle fragments Selene reads.

## Trade-offs

- Waybar is no longer a dormant fallback, so falling back to it now needs a `paru -S` plus a configuration restore from Git.
- The palette contract no longer validates any consumer stylesheet, only the bundle fragments. That coverage was about Waybar's own CSS, which no longer exists.
- The bundle fragments keep a tool name that no longer matches anything installed, which is confusing unless the naming is explained.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Removing a fragment thinking it is Waybar's own configuration. | Out of scope and called out explicitly: the 13 `waybar.css` bundle fragments stay, and the palette contract still asserts all 11 semantic mappings against them. |
| A menu entry survives without its catalog entry, making the checkbox decorative. | `TestDefaultCategories_PackageNamesMatchCatalogGroups` fails when a menu name is absent from its group. |
| The palette contract silently loses more than Waybar's own stylesheet. | The removed block was enumerated line by line before deletion; every assertion reading a bundle fragment was preserved and the suite still passes. |
| An existing installation keeps an orphaned `~/.config/waybar/`. | `installation-transaction` requires installed targets omitted from desired to be explicit removals, backed up and inventoried before deletion. |
| Losing the last guard on the Hyprland bindings or autostart. | `tests/moonarch-theme-selector_test.sh` lost exactly one assertion — the deleted stylesheet's `@import` — and now runs inside `test.sh`. |

## Rollback

Revert through Git to restore the directory and the installer entry. Reinstalling the package is not required beyond that entry, which the revert restores.

## Success criteria

- `home/.config/waybar/` does not exist and is absent from the tracked tree.
- The 13 `home/.local/share/moonarch/themes/*/waybar.css` fragments still exist.
- `aur/waybar-git` appears in neither the `hyprland` catalog group nor the TUI menu.
- `theme-selector` still reloads Waybar when it is running.
- `bash test.sh`, `bash tests/moonarch-theme-selector_test.sh` and `go test ./...` pass.
- No file in the repository reads `home/.config/waybar/`.
