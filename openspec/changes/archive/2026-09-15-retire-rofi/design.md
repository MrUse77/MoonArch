# Design: Retire Rofi

## Decision summary

| Decision | Choice | Rationale |
| --- | --- | --- |
| Interactive picker | Delegates to Selene's `openThemes` | Selene already drives the selector through `--list` and `--apply`; the picker was a second implementation of the same choice. |
| No-argument failure mode | Non-zero exit naming `--list` and `--apply` | The path now needs a running shell; failing loudly is the honest alternative to a silent success that opens nothing. |
| Bundle `rofi.rasi` fragment | Deleted, and dropped from `required_files` | With the launcher gone nothing reads it. Removing only the requirement without the files would leave 12 orphans. |
| Stale-fragment tolerance | Kept and asserted | `validate_bundle` iterates only the required list, so bundles from older releases stay valid. The fixtures deliberately keep writing a stale `rofi.rasi`. |
| `waybar.css` fragments | Untouched | Selene derives every colour token from them. |
| Waybar reload branch | Untouched | Best-effort, inert when Waybar is absent, and named by the capability spec. |
| Installer | `rofi` dropped from group and menu | The tool is gone; offering it is misleading surface. |
| Capability delta | Two modified requirements | Requirement 1 counted "four supported consumers" and requirement 3 listed Rofi among the fragments. |

## Why the picker is a delegation and not a reimplementation

`theme-selector` and Selene have a division of labour that already worked before this change:

```text
Selene's Themes mode ──→ theme-selector --list      (enumerate validated IDs)
                     └──→ theme-selector --apply ID  (validate, swap, reload)
```

The no-argument path predated that and used a Rofi `-dmenu` grid fed by the same `valid_ids`. Migrating it therefore means deleting a picker, not writing one: the path now invokes `qs -c selene ipc call selene openThemes` and exits, capturing nothing on stdout and validating nothing locally, because the `--apply` invocation Selene makes afterwards owns validation.

That also means the no-argument path must **not** exit 0 when Quickshell is absent. A delegation that silently succeeds while opening nothing is indistinguishable from success in any assertion; the suite proves the failure case with a fake `qs` that fails.

## Relaxing the fragment requirement

`required_files` becomes `hyprland.conf hyprland.lua waybar.css ghostty.conf`. `validate_bundle` iterates that list and checks each file exists, so a bundle carrying an extra `rofi.rasi` still validates. This is a relaxation, and it is asserted: the test fixtures keep writing a stale `rofi.rasi` into every bundle they build, and every `--list`, `--apply` and no-argument scenario passes with it present.

Deleting the 12 real fragments is the separate data cleanup. Note the count: the themes root holds 12 bundles plus a `current` symlink to `tokyo-night`, so a glob over `themes/*/rofi.rasi` reports 13 paths while the distinct files are 12. The symlink must not be dereferenced or removed.

## Coverage removed from the palette contract

Removed: `rofi.rasi` from the protected paths, files and hashes; `fragment_rasi_value`; `rofi.rasi` from `required_files`; and the four per-bundle Rofi semantic mappings.

Preserved: the protected Tokyo Night bundle mechanism for the remaining five files with byte hashes, the current-symlink check, the bundle count, manifest identity checks, per-bundle required files, the Waybar aliases, every Hyprland conf and Lua mapping, all 16 Ghostty palette entries plus background, foreground, selection, cursor and cursor-text, and the Tokyo Night Lua-to-conf cross-checks.

The closing message's `11` counts source-mapped bundles, not fragment consumers, so no renumbering was needed for it.

## Guard widening

The retired-tool reference guard in the selector suite now rejects `rofi` alongside `eww` and `dunst`, under `home/` and excluding the Selene submodule. It uses a word-boundary match: a substring match would false-positive on `profile` and `accel_profile`, which appear in the Hyprland configuration.

## Verification plan

- `bash tests/moonarch-theme-palette_test.sh` — must pass with every non-Rofi assertion intact.
- `bash tests/moonarch-theme-selector_test.sh` — must pass with the delegation scenarios and the widened guard.
- `bash test.sh` — both suites plus the Docker Stow validation.
- In `cli/`: `gofmt -l .`, `go build ./...`, `go vet ./...`, `go test ./...`.
- A grep for `rofi` across the tree, excluding the historical palette dumps and the archived changes.

## Rollout and rollback

An existing installation receives five Rofi files and twelve fragment deletions as planned removals with a backup, per `installation-transaction`. No package operation is required.

Rollback is `git revert`. A partial revert is not safe: the selector's relaxed `required_files` and the fragment deletion are coupled.

## Risks and constraints

- The interactive path narrows from "works without the shell" to "needs a running Selene". The non-interactive modes remain the Quickshell-independent routes, which is what makes the selector usable from a terminal and from Selene itself.
- Dunst remains installed and pre-selected although its configuration was retired in an earlier change, so the installer still pulls one package whose configuration is gone. Recorded as out of scope.
- The `waybar.css` fragments keep a name that no longer matches an installed tool, for the same reason they were kept in the previous slice.
