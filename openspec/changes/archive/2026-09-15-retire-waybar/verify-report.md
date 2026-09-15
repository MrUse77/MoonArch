# Verify Report: Retire the Waybar configuration and package

## Result Contract

- **status:** PASS
- **executive_summary:** Waybar's own configuration and installer entry are gone, while the 13 theme bundle `waybar.css` fragments Selene reads are untouched. All gates pass. The palette contract lost only its stylesheet coverage and kept every bundle-fragment assertion; the selector suite lost exactly one assertion.
- **artifacts:**
  - `openspec/changes/retire-waybar/verify-report.md`
  - Inputs read: `proposal.md`, `design.md`, `tasks.md`, `openspec/specs/moonarch-theme-selector/spec.md`
- **next_recommended:** archive
- **risks:** Waybar is no longer a dormant fallback, so falling back now needs a package install plus a configuration restore. The bundle fragments keep a tool name that no longer matches anything installed. Rofi remains and still needs its own slice.
- **skill_resolution:** none (no skill paths were injected)

## Structured Status and Action Context

```yaml
changeName: retire-waybar
artifactStore: openspec
changeRoot: /home/agustin/Dev/dotfiles/openspec/changes/retire-waybar
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
| 1 | `home/.config/waybar/` absent from the tracked tree | `test -d` reports missing; `git status --short` reports three deletions | PASS |
| 2 | The 13 bundle `waybar.css` fragments still exist | `ls home/.local/share/moonarch/themes/*/waybar.css \| wc -l` → 13 | PASS |
| 3 | `aur/waybar-git` in neither the catalog group nor the menu | Removed from `plan.GroupHyprland` and from the Hyprland category | PASS |
| 4 | `theme-selector` still reloads Waybar when running | `home/.local/bin/moonarch/theme-selector:72-84` untouched | PASS |
| 5 | All gates pass | See Validation Commands | PASS |
| 6 | No file reads `home/.config/waybar/` | Reference sweep before deletion found exactly two readers, both test assertions, both handled | PASS |
| 7 | Documents no longer claim Waybar is installed or configured | README's only mentions are the fragment note and the removal note; CONTRIBUTING's are negative commit-message examples | PASS |

## Task Completion

All six tasks in `tasks.md` are complete.

## Validation Commands

| Command | Result |
| --- | --- |
| `bash tests/moonarch-theme-palette_test.sh` | PASS — protected Tokyo Night bundle and 11 semantic mappings; shared Waybar rules; Ghostty clean config |
| `bash tests/moonarch-theme-selector_test.sh` | PASS — 18 scenarios, consumer bindings, autostart guard, retired-tool guard |
| `gofmt -l .` (in `cli/`) | PASS — no files reported |
| `go build ./...`, `go vet ./...` (in `cli/`) | PASS |
| `go test ./...` (in `cli/`) | PASS — all packages ok |
| Directory-vs-tree consistency check | PASS — every `home/.config/` directory is listed and nothing nonexistent is |

### Coverage accounting

The palette contract's removed block was enumerated before deletion: the `style_file` variable, the `assert_rule_uses` awk helper, the fixed-colour-literal check and 13 rule-alias checks — all reading `home/.config/waybar/style.css`. Preserved: the protected bundle path, hash and set checks; four `assert_define` aliases per bundle; all 11 semantic mappings per bundle including the Waybar text, background, accent and urgent mappings read from `bundle/waybar.css`; and the Ghostty clean-config check.

The selector suite's diff is a single-line deletion. The retired-tool guard, the Selene binding assertion, the autostart guard, the Rofi and Ghostty binding assertions and all 18 scenarios are byte-identical.

### Note on the "shared Waybar rules use theme aliases" assertion

The palette contract's summary line still reads `PASS: shared Waybar rules use theme aliases`. That assertion covered the deleted stylesheet, so its message is now the only surviving reference to it inside the suite; the coverage it named is gone. This is cosmetic but worth knowing when reading the gate output.

## Strict TDD Compliance

`openspec/config.yaml` reports `strict_tdd: false` for the root project, whose gate is the two shell suites plus `test.sh`. The `cli/` subproject has `strict_tdd: true`; the existing menu/catalog agreement test covers the installer change unmodified, because Waybar left both sides and they still agree.

No new behavioural test was added: this change removes a tool and removes exactly the coverage that read it. The guard against the fragment mistake — the one that would actually break the shell — is the preserved bundle-fragment coverage in the palette contract.

## Review Workload / PR Boundary

This slice is ~533 changed lines: 440 deletions of Waybar's configuration and 88 deletions of palette coverage, against roughly five authored lines. The budget is exceeded by line count but not by review burden.

## Blockers

None.

Two things remain explicitly out of scope and are recorded rather than silently absorbed:

1. **Rofi** — `theme-selector` still opens its no-argument picker through `rofi/scripts/launch`, and the palette contract still asserts that launcher composes the theme fragment. Retiring it requires migrating the picker to Selene's `openThemes` and deciding the fate of the 13 `rofi.rasi` bundle fragments, which means a capability delta.
2. **The `waybar.css` fragment name** — the fragments are live but named after a tool that is no longer installed. Renaming them would touch 13 bundles and the fragment contract, so it is a deliberate follow-up rather than part of this retirement.
