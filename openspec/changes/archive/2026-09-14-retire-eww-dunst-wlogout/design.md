# Design: Retire the Eww and Dunst widget stack

## Decision summary

| Decision | Choice | Rationale |
| --- | --- | --- |
| Tools retired | Eww and Dunst | Both are unreferenced in `home/` after the Selene migration; their roles belong to Selene's dashboard and notification server. |
| Tools retained | Waybar and Rofi | Their configuration is still reachable: the palette contract asserts Waybar's stylesheet and Rofi's launcher composes the theme fragment. |
| Removal mechanism | Deleted from the tree | The transaction layer turns "installed target omitted from desired" into an explicit removal, so existing installations are handled, not orphaned. |
| Installer | `aur/eww` and `aur/wlogout` dropped from catalog and menu | Installing a widget host and a session menu that nothing launches is misleading surface. |
| Specs | No delta; `skip_specs: true` | No file under `openspec/specs/` mentions Eww, Wlogout or Dunst. |
| Waybar and Rofi | Untouched | Each needs its own prerequisite: a palette-contract change for Waybar, a picker migration plus a bundle-contract change for Rofi. |

## Why these two and not the other two

The four tools Selene replaces are not equally removable, because removal is gated by what still reaches them:

| Tool | References in `home/` before removal | Gate |
| --- | --- | --- |
| Eww | 3 — `eww daemon` in the autostart, `Super+N`, Waybar's `custom/notification` click | None once those three are repointed. |
| Dunst | 0 — it left the autostart in the previous change | None. |
| Waybar | `pgrep -x waybar` and `pkill -SIGUSR2 waybar` in `theme-selector`, plus the palette contract asserting rules in `home/.config/waybar/style.css` | Requires editing the theme palette contract. |
| Rofi | `theme-selector` line 125 opens its no-argument picker through `rofi/scripts/launch`, and the palette contract asserts that launcher composes the fragment | Requires migrating the picker and relaxing the bundle contract. |

Eww and Dunst therefore form the only clean slice. The three Eww references were repointed to `seleneIpc .. "toggleDashboard"` and to `qs -c selene ipc call selene toggleDashboard` before any file was touched, which is what makes the deletion safe rather than hopeful.

## Reference inventory

Deleted from `home/`:

```text
.config/eww/eww.yuck              widget definitions
.config/eww/eww.scss              widget styles
.config/eww/image.png             asset
.config/eww/119166871.png         asset
.config/eww/scripts/usrctl.sh     control-center toggle, formerly Super+N
.config/eww/scripts/getvol.sh     volume reader
.config/eww/scripts/getlight-loop.sh
.config/eww/scripts/music.sh      media metadata
.config/eww/scripts/pmusic.sh     media control
.config/eww/scripts/batico.sh     battery reader
.config/eww/scripts/batest.sh     battery helper
.config/eww/scripts/cover.png     asset
.config/dunst/dunstrc             notification daemon configuration
```

Thirteen tracked files. Assets are deleted with the configuration because nothing else references them.

## Removal semantics for existing installations

Deleting a directory in the repository does not delete it in a user's home. `installation-transaction` already specifies what happens:

- Installed targets omitted from desired MUST be explicit removals.
- A removal MUST be backed up and inventoried before deletion.
- An already-absent removal target MUST be skipped and MUST NOT be recreated.
- A failed transaction MUST restore deletions.

So the user-visible effect of this change on an existing installation is a planned removal with a backup, not an orphaned directory. No new machinery is required, and no spec change is required for it.

## Installer changes

`aur/eww` and `aur/wlogout` are removed from the `theming` group in `collectPackages` and from the Theming & Appearance category in the TUI menu. Both sides must change together: exclusion matches names verbatim, and `TestDefaultCategories_PackageNamesMatchCatalogGroups` fails if a menu entry's name is absent from its group.

The category description drops its mention of widgets, since the category now covers GTK/Qt theming and the prompt.

`cli/pkg/installer/packages.go` still names `aur/eww` and `aur/wlogout`. That file has no callers and is deliberately left alone; correcting or deleting dead code is separate work.

## Verification plan

### Static checks

- `gofmt -l .`, `go build ./...`, `go vet ./...` in `cli/`.
- `go test ./...` in `cli/`, including the menu/catalog agreement test for the narrowed `theming` group.
- Confirm `home/.config/eww/` and `home/.config/dunst/` are absent and that `git status` reports thirteen deletions.
- Confirm no reference to `eww` or `dunst` remains under `home/`.

### Behavioral checks

- `bash tests/moonarch-theme-selector_test.sh` — the selector scenarios, the consumer bindings, the autostart exclusivity guard and the retired-reference guard.
- `bash test.sh` — theme palette contract and the isolated Stow validation in Docker.

### Negative validation

The retired-reference guard is exercised by creating files under `home/` that mention `eww` and, separately, `dunst`, confirming the guard fails in both cases, then removing them and confirming the suite returns to green.

## Rollout and rollback

Rollout needs no user action beyond applying the new configuration release; existing installations receive the two targets as planned removals.

Rollback is `git revert`. Reinstalling Eww or Dunst is possible again because the revert restores the installer entries.

## Risks and constraints

- This shrinks the dormant-fallback set from four tools to two, so reverting Eww or Dunst means restoring configuration from Git rather than flipping a binding. That is the intended trade: carrying unreachable configuration has a cost of its own.
- Notification delivery now depends on Selene alone. This is already the runtime state; the change only makes it true of the installer too.
- Waybar and Rofi remain, so the repository still carries two configurations that nothing launches. Removing them is the next slice, not this one.
