# Verify Report: Drop Dunst from the installer

## Result Contract

- **status:** PASS
- **executive_summary:** Dunst is no longer offered or pre-selected by the installer, and the fallback test whose subject disappeared is replaced by one that locks all five retirements in place. Both shell guards still name Dunst and are unchanged. Every gate passes.
- **artifacts:**
  - `openspec/changes/retire-dunst-package/verify-report.md`
  - Inputs read: `proposal.md`, `design.md`, `tasks.md`, `openspec/specs/` (retired-tool search)
- **next_recommended:** archive
- **risks:** Rolling back to Dunst now needs a package install as well as a configuration restore, matching Waybar and Rofi. Removing a package from the catalog does not uninstall anything on an existing machine, and the installer has no uninstall path.
- **skill_resolution:** none (no skill paths were injected)

## Structured Status and Action Context

```yaml
changeName: retire-dunst-package
artifactStore: openspec
changeRoot: /home/agustin/Dev/dotfiles/openspec/changes/retire-dunst-package
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
| 1 | `dunst` in neither the catalog group nor the menu | Removed from `plan.GroupHyprland` and from the Hyprland category | PASS |
| 2 | No category offers the five retired packages | `TestDefaultCategories_QuickshellReplacesRetiredTools` | PASS |
| 3 | `aur/quickshell-git` stays offered and pre-selected | Same test | PASS |
| 4 | `go test ./...` passes in `cli/` | See Validation Commands | PASS |
| 5 | No document claims those packages are still installed | README and `openspec/config.yaml` name Dunst among the packages no longer installed | PASS |
| 6 | Both shell guards still name `dunst` | `tests/moonarch-theme-selector_test.sh` autostart guard and `home/` reference guard, byte-identical | PASS |

## Task Completion

All five tasks in `tasks.md` are complete.

## Validation Commands

| Command | Result |
| --- | --- |
| `gofmt -l .` (in `cli/`) | PASS — no files reported |
| `go build ./...`, `go vet ./...` (in `cli/`) | PASS |
| `go test ./...` (in `cli/`) | PASS — all packages ok |
| `bash test.sh` | PASS — palette contract, 20 selector scenarios, Docker build and isolated Stow validation |
| `grep -rniw dunst` across the tree | Only intentional mentions: README, `openspec/config.yaml`, the two shell guards, the installer test, the dead legacy list, and archived changes |

### Negative validation

The replacement test was written before the catalog changed and failed with:

```text
catalog_menu_test.go:65: dunst must not be offered: Selene replaces it and its configuration was removed
```

It passed once the catalog and menu stopped offering Dunst. This is the branch's clearest RED-then-GREEN cycle: a `cli/` unit test failing on a real behavioural claim rather than a suite assertion list changing.

## Strict TDD Compliance

The `cli/` subproject has `strict_tdd: true`, and this slice satisfies it: T1 preceded T2, the RED failure was observed on the assertion the change is about, and the GREEN came from the catalog and menu edits rather than from weakening the test.

The root project has `strict_tdd: false`; its gate is the two shell suites plus `test.sh`, all of which pass unchanged.

## Note on the replacement

`TestDefaultCategories_QuickshellLeadsDormantFallbacks` is gone, not renamed. Its body iterated a fallback list that had shrunk to one member; with that member retired there was nothing left for it to assert, so keeping the name would have left a test asserting a policy the branch no longer holds. Its replacement asserts something strictly stronger: that none of the five retired packages is offered anywhere, which fails if any retirement in this branch is undone.

The coverage that is *not* replaced is the ordering check, which had no remaining subject.

## Review Workload / PR Boundary

Roughly 90 changed lines, under the 400-line budget, and the only slice in the branch that is. It replaces a test rather than deleting configuration, so its authoring cost is higher relative to its size than the other slices.

## Blockers

None.

One item is recorded as out of scope: `cli/pkg/installer/packages.go` still names `waybar`, `wofi`, `dunst`, `aur/eww` and `aur/wlogout` in a legacy list with no callers. It has been out of scope in every retirement in this branch and remains so.
