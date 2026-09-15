# Design: Retire the Waybar configuration and package

## Decision summary

| Decision | Choice | Rationale |
| --- | --- | --- |
| Waybar's own configuration | Deleted | Nothing starts Waybar and nothing reads its files. |
| Bundle `waybar.css` fragments | Kept | Selene derives its colour tokens from them; the name is historical, the data is live. |
| Installer entry | Removed | Offering a bar that nothing starts is misleading surface. |
| `theme-selector` reload branch | Kept | Best-effort and inert when Waybar is absent; the spec names Waybar as a reloaded consumer, so removing it would need a delta for no runtime benefit. |
| Palette contract | Narrowed to the bundle fragments | Its Waybar-stylesheet assertions described a file that no longer exists. |
| Capability delta | None; `skip_specs: true` | The spec's Waybar references remain true: the fragments exist and are still reloaded. |

## The fragment asymmetry that shapes this change

`waybar.css` appears in two unrelated roles, and only one of them is Waybar's:

| Role | Path | Fate |
| --- | --- | --- |
| Waybar's own stylesheet | `home/.config/waybar/style.css` | Deleted. It `@import`ed the active theme fragment and styled Waybar's modules. |
| Theme bundle fragment | `home/.local/share/moonarch/themes/*/waybar.css` | **Kept.** Selene's `Services/Theme.qml` reads `.../current/waybar.css` to derive every colour token the shell renders with. |

A change that treats the two as one would break the running shell while looking like a tidy cleanup. The palette contract is the guard: it asserts four colour aliases per bundle and 11 semantic mappings, including the Waybar alias mappings against `bundle/waybar.css`. All of those stay; only the assertions that opened `home/.config/waybar/style.css` are removed.

## Coverage removed, enumerated

The deleted block in `tests/moonarch-theme-palette_test.sh` read only the stylesheet:

- the `style_file` variable
- the `assert_rule_uses` helper, an awk pass over that file
- the fixed-colour-literal check and 13 rule-alias checks: `.modules-left`, `#workspaces button`, `#workspaces button.active`, `#workspaces button:hover`, `#groups-hardware`, `#taskbar button:hover`, `#tray:hover`, `#custom-launcher:hover`, `#battery.warning`, `#battery.charging`, `#battery`, `#clock:hover`, `#custom-pacman:hover`

Preserved: the protected Tokyo Night bundle path, hash and set checks; the four `assert_define` aliases per bundle; all 11 semantic mappings per bundle including the Waybar text, background, accent and urgent mappings read from `bundle/waybar.css`; and the Ghostty clean-config check.

## Reference sweep

Before deleting, every file in the directory was read and the tree was searched for references to it. Findings:

- `colors.css` is **not** imported by `style.css`. The stylesheet imports the theme bundle directly, so `colors.css` was already orphaned inside its own directory and nothing outside referenced it.
- External readers of the directory were exactly two test assertions: one in the palette contract and one in the selector suite. Both are handled above.
- Selene binds only to `.../current/waybar.css` through its own `Services/Theme.qml`, never to `~/.config/waybar/`.

## Verification plan

- `bash tests/moonarch-theme-palette_test.sh` — must still pass with the bundle-fragment assertions intact.
- `bash tests/moonarch-theme-selector_test.sh` — must still pass with exactly one assertion removed.
- In `cli/`: `gofmt -l .`, `go build ./...`, `go vet ./...`, `go test ./...`.
- `bash test.sh` — palette contract, then the selector contract, then the Docker Stow validation.
- Confirm the 13 bundle fragments still exist and that no file reads `home/.config/waybar/`.

## Rollout and rollback

An existing installation receives `~/.config/waybar/` as a planned removal with a backup, per `installation-transaction`. No package operation is needed.

Rollback is `git revert`; the revert restores both the directory and the installer entry.

## Risks and constraints

- Waybar stops being a dormant fallback. Falling back now costs a package install plus a configuration restore, which is the intended trade for not carrying unreachable configuration.
- The bundle fragments keep a name that no longer corresponds to an installed tool. That is worth a comment in the theme documentation eventually, but renaming them would touch 13 bundles and the fragment contract for no runtime gain.
- The palette contract now validates the bundle side of the contract only. The consumer-stylesheet side has no remaining subject.
