# Verify Report: Retire Rofi

## Result Contract

- **status:** PASS
- **executive_summary:** Rofi is gone from the desktop, the theme contract and the installer. The selector's interactive path delegates to Selene and fails loudly without it. Verification also uncovered and repaired a pre-existing defect in `--list`: it exited non-zero whenever the last entry of the themes root was not a valid bundle, which is the default shape when a themes root holds few bundles because `current` always sorts after them.
- **artifacts:**
  - `openspec/changes/retire-rofi/verify-report.md`
  - Inputs read: `proposal.md`, `design.md`, `tasks.md`, `openspec/specs/moonarch-theme-selector/spec.md`
- **next_recommended:** archive
- **risks:** The interactive path now needs a running Selene. Dunst remains installed and pre-selected although its configuration was retired earlier. The `waybar.css` fragments keep a name that matches no installed tool.
- **skill_resolution:** none (no skill paths were injected)

## Structured Status and Action Context

```yaml
changeName: retire-rofi
artifactStore: openspec
changeRoot: /home/agustin/Dev/dotfiles/openspec/changes/retire-rofi
artifacts:
  proposal: done
  design: done
  tasks: done
  specs: done
  verifyReport: done
actionContext:
  mode: repo-local
  workspaceRoot: /home/agustin/Dev/dotfiles
  branch: feat/selene-desktop-shell
```

## Acceptance Criteria Coverage

| # | Criterion | Evidence | Result |
| --- | --- | --- | --- |
| 1 | No `rofi.rasi` under any bundle and not required | `ls themes/*/rofi.rasi` → none; `required_files=(hyprland.conf hyprland.lua waybar.css ghostty.conf)` | PASS |
| 2 | A bundle carrying a stale `rofi.rasi` still validates | Direct run with a stale fragment present: `--list` printed the bundle | PASS |
| 3 | No-argument path invokes Selene and captures nothing | Direct run with a logging `qs`: exit 0, log shows `qs -c selene ipc call selene openThemes`, no stdout | PASS |
| 4 | It fails naming the non-interactive routes without Quickshell | Direct run with a failing `qs`: exit 1, stderr names `--list` and `--apply <theme-id>` | PASS |
| 5 | The 13 `waybar.css` fragments still exist | `ls themes/*/waybar.css \| wc -l` → 13 | PASS |
| 6 | `rofi` in neither the catalog group nor the menu | Removed from `plan.GroupHyprland` and the Hyprland category | PASS |
| 7 | No configuration, documentation or template offers Rofi | Grep leaves only intentional mentions in README, the installer test comment, and archived changes | PASS |
| 8 | All gates pass | See Validation Commands | PASS |

## Defect found and repaired during verification

`--list` printed the correct IDs and then exited **1**. Root cause:

```bash
for candidate in "$themes_real"/*; do
    ...
    validate_bundle "$id" && printf '%s\n' "$id"
done | sort
```

Under `set -euo pipefail`, the loop's final iteration determines the subshell's status. When the last entry of the themes root fails validation, the `&&` short-circuits to non-zero, `pipefail` propagates it through the pipeline, and `set -e` terminates the script before its `exit 0`.

`current` is always an invalid identity and sorts after every theme whose id begins with a lower letter, so a themes root holding only early-alphabetical bundles always hits this. The repository's own themes root does not, because `tokyo-night` sorts last and is valid, and the suite's `--list` fixture does not either, because it also builds `tokyo-night`. Both masked it.

Replaced with an `if` form so each iteration yields success. A scenario was added that builds only `alpha` plus `current`, asserting `--list` succeeds and prints just `alpha`; it fails against the previous implementation and passes now.

This is a pre-existing defect, not introduced by this change: the same direct run against the committed selector exits 1. It is delivered as its own `fix` commit.

## Task Completion

All ten tasks in `tasks.md` are complete.

## Validation Commands

| Command | Result |
| --- | --- |
| `bash tests/moonarch-theme-palette_test.sh` | PASS — protected Tokyo Night bundle and 11 semantic mappings; Ghostty clean config |
| `bash tests/moonarch-theme-selector_test.sh` | PASS — 20 scenarios |
| `bash test.sh` | PASS — both suites plus Docker build and isolated Stow validation |
| `gofmt -l .`, `go build ./...`, `go vet ./...`, `go test ./...` (in `cli/`) | PASS — all packages ok |
| `openspec validate retire-rofi --type change --strict` | PASS — change is valid |
| Direct selector runs against a hand-built themes root | PASS — delegated invocation, failure mode, `--list` exit status and stale-fragment tolerance each observed |

### Negative validation

- A logging stub for `qs` confirms the exact delegated command and that nothing is captured on stdout.
- A failing stub for `qs` confirms exit 1 with a message naming both non-interactive routes.
- The new `--list` scenario was run against the pre-fix implementation through `git stash` and failed with `--list failed when a trailing themes-root entry is not a valid bundle`, then passed after the fix.

## Strict TDD Compliance

`openspec/config.yaml` reports `strict_tdd: false` for the root project, whose gate is the two shell suites plus `test.sh`. The `cli/` subproject has `strict_tdd: true`; its existing agreement test covers the installer change unmodified.

The selector delegation was written test-first and its RED run is informative: it failed with `no-argument path did not open the Selene theme picker` and simultaneously exposed the old path's silent-failure mode, which exited 0 with its launcher missing. The `--list` fix likewise has explicit RED evidence.

## Coverage accounting

**Palette contract** — removed: `rofi.rasi` from protected paths, files and hashes; `fragment_rasi_value`; `rofi.rasi` from required files; the four per-bundle Rofi mappings. Preserved: the protected Tokyo Night mechanism for the remaining five files with byte hashes, the current-symlink check, the bundle count, manifest identity checks, per-bundle required files, the Waybar aliases, every Hyprland conf and Lua mapping, all 16 Ghostty entries plus background, foreground, selection, cursor and cursor-text, and the Tokyo Night Lua-to-conf cross-checks.

**Selector suite** — removed: the `ROFI_*` fixtures, the fake launcher and the cancellation scenario, and the two launcher consumer assertions. Added: the delegation scenario, the unavailable-Quickshell scenario, a `--list` trailing-entry scenario, and a `rofi` term in the retired-tool guard. Preserved byte-identical: the Selene binding assertion, the autostart guard and the remaining consumer assertions.

**Guard note** — the widened guard uses a word-boundary match. A substring match would false-positive on `profile` and `accel_profile` in the Hyprland configuration.

## Review Workload / PR Boundary

This slice is roughly 570 changed lines, dominated by deletion of Rofi's configuration, its 12 theme fragments and the palette coverage that read them. The authored surface is about thirty lines.

## Blockers

None.

One inconsistency is recorded rather than fixed: **Dunst remains installed and pre-selected although its configuration was retired** in `retire-eww-dunst-wlogout`. The installer therefore still pulls one package whose configuration no longer exists, and the dormant-fallback policy that justified it is now vacuous, since all four of the tools it named have had their configuration removed. That reverses an archived decision and deserves its own change.
