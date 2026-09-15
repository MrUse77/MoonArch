# Design: Drop Dunst from the installer

## Decision summary

| Decision | Choice | Rationale |
| --- | --- | --- |
| Dunst package | Dropped from group and menu | Its configuration is gone; pre-selecting it installs a daemon with nothing to read. |
| Fallback test | Replaced by a retirement lock | Its subject was the last member of a policy whose other three members had already been retired. |
| Autostart and reference guards | Untouched | Both still name `dunst`, and now guard against reintroduction rather than describing state. |
| Capability delta | None; `skip_specs: true` | No file under `openspec/specs/` mentions Dunst. |
| Uninstalling from a live system | Out of scope | The installer never uninstalls; `paru -Rns dunst` stays a user decision. |

## Why the fallback policy is being removed rather than re-justified

Three archived decisions shaped it, and each narrowed it:

1. `selene-desktop-shell` kept Waybar, Rofi, Eww and Dunst installed and configured so a session could roll back without a package install.
2. `retire-eww-dunst-wlogout` deleted Eww's and Dunst's configuration, keeping only Dunst's package, on the grounds that the rollback story survived.
3. `retire-waybar` and `retire-rofi` deleted those tools' configuration *and* installer entries, which left Dunst as the policy's only member.

A policy with one member and no configuration behind it is not a policy; it is a pre-selected package nobody can use. Rather than invent a new justification, this change removes the member and records that the fallback path is now Git-only for all four tools, uniformly.

## The replacement test

`TestDefaultCategories_QuickshellLeadsDormantFallbacks` asserted that Quickshell preceded its fallbacks and that each stayed pre-selected. With no fallback left, its body had nothing to iterate over.

It becomes `TestDefaultCategories_QuickshellReplacesRetiredTools`, which keeps the part that still has meaning and adds the part that locks the migrations in:

- `aur/quickshell-git` is offered somewhere and pre-selected in its category.
- None of `aur/waybar-git`, `rofi`, `dunst`, `aur/eww` or `aur/wlogout` is offered in any category.

That is a stronger assertion than the one it replaces: it fails if any retirement is undone, where the old test only failed if a fallback was reordered.

The test was written before the catalog and menu changed, and its RED run reported `dunst must not be offered: Selene replaces it and its configuration was removed`.

## Relation to the reference guards

The selector suite keeps both of its guards naming `dunst`:

- the autostart guard rejects `waybar`, `dunst` or `eww` in the `hl.on("hyprland.start")` block;
- the reference guard rejects any `eww` or `dunst` reference under `home/`, ignoring binaries and the Selene submodule.

Neither is narrowed here. They protected against reintroduction while Dunst was installed-but-dormant, and they protect against reintroduction now that it is gone entirely — which is worth strictly more.

## Verification plan

- `gofmt -l .`, `go build ./...`, `go vet ./...`, `go test ./...` in `cli/`, with the RED evidence for the replacement test.
- `bash test.sh` — both shell suites plus the Docker Stow validation, to confirm the guards still pass now that no category offers Dunst.
- A grep for `dunst` across the tree, excluding the historical review document and the archived changes.

## Rollout and rollback

Rollout needs no user action. Removing a package from the catalog does not uninstall anything, and the installer has no uninstall path; a machine that already has Dunst keeps it until the user removes it.

Rollback is `git revert`, restoring both installer entries.

## Risks and constraints

- The `hyprland` group now installs Hyprland, its satellites, Quickshell, the portals and `nwg-look`. Nothing in it is a fallback for anything.
- This does not address `cli/pkg/installer/packages.go`, the dead legacy list, which still names all five retired packages. It has no callers and is recorded as out of scope in every retirement in this branch.
