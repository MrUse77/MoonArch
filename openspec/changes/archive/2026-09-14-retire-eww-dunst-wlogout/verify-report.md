# Verify Report: Retire the Eww and Dunst widget stack

## Result Contract

- **status:** PASS
- **executive_summary:** Eww and Dunst are retired: thirteen tracked files deleted, both packages dropped from the installer catalog and menu, and every reference repointed to Selene before deletion. All repository gates pass. The retired-reference guard was confirmed to fail against both a reintroduced `eww` reference and a reintroduced `dunst` reference, and the autostart guard was confirmed against three variants.
- **artifacts:**
  - `openspec/changes/retire-eww-dunst-wlogout/verify-report.md`
  - Inputs read: `proposal.md`, `design.md`, `tasks.md`, `openspec/config.yaml`, `openspec/specs/` (retired-tool search)
- **next_recommended:** archive
- **risks:** The dormant-fallback set shrinks from four tools to two, so reverting Eww or Dunst now requires restoring configuration from Git. Notification delivery depends on Selene alone, which was already true at runtime before this change. Waybar and Rofi remain and still need their own change.
- **skill_resolution:** none (no skill paths were injected)

## Structured Status and Action Context

```yaml
changeName: retire-eww-dunst-wlogout
artifactStore: openspec
changeRoot: /home/agustin/Dev/dotfiles/openspec/changes/retire-eww-dunst-wlogout
skipSpecs: true
artifacts:
  proposal: done
  design: done
  tasks: done
  specs: not applicable (declared skip_specs)
  verifyReport: done
actionContext:
  mode: repo-local
  workspaceRoot: /home/agustin/Dev/dotfiles
  branch: feat/selene-desktop-shell
```

## Acceptance Criteria Coverage

| # | Criterion | Evidence | Result |
| --- | --- | --- | --- |
| 1 | `home/.config/eww/` and `home/.config/dunst/` absent from the tracked tree | `ls` reports both missing; `git status --short` reports thirteen deletions | PASS |
| 2 | No file under `home/` references `eww` or `dunst` | `grep -rqEw --exclude-dir=selene '(eww\|dunst)' home/` returns nothing | PASS |
| 3 | `aur/eww` and `aur/wlogout` absent from catalog and menu | Removed from `plan.GroupTheming` and from the Theming & Appearance category | PASS |
| 4 | `Super+N` and Waybar's `custom/notification` open Selene's dashboard | Both expand to `qs -c selene ipc call selene toggleDashboard` | PASS |
| 5 | `test.sh`, the selector suite and `go test ./...` pass | See Validation Commands | PASS |
| 6 | No spec delta required | `grep -rniw 'eww\|wlogout\|dunst' openspec/specs/` returns nothing; `skip_specs: true` declared | PASS |

## Task Completion

All five tasks in `tasks.md` are complete. Archiving is not listed as a task, matching the repository's existing changes.

## Validation Commands

| Command | Result |
| --- | --- |
| `gofmt -l .` (in `cli/`) | PASS — no files reported |
| `go build ./...` (in `cli/`) | PASS |
| `go vet ./...` (in `cli/`) | PASS |
| `go test ./...` (in `cli/`) | PASS — 8 packages ok, 2 with no test files |
| `bash tests/moonarch-theme-palette_test.sh` | PASS — 3 assertions |
| `bash tests/moonarch-theme-selector_test.sh` | PASS — 18 scenarios |
| `bash test.sh` | PASS — palette contract, Docker build, isolated Stow validation |
| `grep -rniw 'eww\|wlogout\|dunst' openspec/specs/` | No matches — confirms `skip_specs` |

### Negative validation

- Injecting `eww daemon` into the Hyprland autostart trips the autostart guard.
- Injecting `dunst` alone into the autostart trips the autostart guard.
- Injecting `waybar` alone into the autostart trips the autostart guard.
- Creating `home/.config/probe/probe.conf` containing `eww` trips the retired-reference guard.
- Creating `home/.config/probe2.conf` containing `dunst` trips the retired-reference guard.

All injected files were removed and the suite returned to green.

## Strict TDD Compliance

`openspec/config.yaml` reports `strict_tdd: false` for the root project, whose gate is the shell suite and `test.sh`. The `cli/` subproject has `strict_tdd: true`; its existing menu/catalog agreement test covers the installer change unmodified, and needed no new test because removing both sides keeps names matched.

The guard added in this change was validated by reproducing the defect it guards against, not merely by passing.

One defect was found and fixed during verification: the autostart guard introduced in the previous change used the pattern `&[[:space:]]*(waybar|dunst|eww)[[:space:]]*&`, which does not match `& eww daemon &` because of the intervening argument. It was replaced with a check over the whole `hl.on("hyprland.start")` block and re-verified against a command with arguments.

## Review Workload / PR Boundary

This change is ~1499 lines: 1481 deletions of one retired tool's configuration and assets, plus ~18 authored lines. The budget is exceeded by line count but not by review burden, since the deletion span carries no behaviour to reason about.

The branch stacks this change on `selene-desktop-shell`, giving a branch total of ~1780 changed lines. Delivering the two as separate PRs keeps the first under budget and isolates the large deletion; delivering them as one PR requires the same size exception to cover both.

## Blockers

None.

Two slices remain explicitly out of scope and are recorded rather than silently absorbed:

1. **Waybar** — its configuration is asserted by `tests/moonarch-theme-palette_test.sh` (the stylesheet import and the theme-alias rules), so removal requires editing that contract. The thirteen `waybar.css` bundle fragments must stay regardless, because Selene derives its tokens from them.
2. **Rofi** — `theme-selector` line 125 opens the no-argument picker through `rofi/scripts/launch`, and the palette contract asserts that the launcher composes the current theme fragment. Removal requires migrating the picker to Selene's `openThemes`, relaxing `required_files` and the bundle contract for the thirteen `rofi.rasi` fragments, and updating both test suites.
