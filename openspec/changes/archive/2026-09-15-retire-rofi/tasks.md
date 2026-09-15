# Tasks: Retire Rofi

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~570 (roughly 525 deletions, mostly configuration and fragments) |
| 400-line budget risk | High by line count, Low by review burden |
| Chained PRs recommended | No |
| Suggested split | Single PR with size exception |
| Delivery scope | single-pr (requires `size:exception`) |
| Chain strategy | size-exception |

```text
Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: High
```

**Rationale for the size exception:** most of the change is deletion of one retired tool's configuration and its 12 theme fragments, plus test coverage whose subject is deleted. The authored surface is about thirty lines: a delegation branch, a relaxed requirement, two delegation scenarios, a widened guard, and installer and documentation rows.

Splitting the fragment deletion from the `required_files` relaxation would leave a commit in which the selector requires a fragment no bundle provides, which is worse than one coherent deletion.

---

## Dependency Graph

```text
T1 (relax required_files) ──→ T2 (delete the 12 fragments)
T3 (picker delegates to Selene) ──→ T4 (selector suite scenarios)
T2, T4 ──→ T5 (palette contract)
T6 (installer) ──→ T7 (docs and templates)
T5, T6, T7 ──→ T8 (spec delta) ──→ T9 (gate)
```

## Task List

- [x] **T1: Relax the fragment requirement** — 1 line changed
- **File:** `home/.local/bin/moonarch/theme-selector`
- **Description:** Drop `rofi.rasi` from `required_files`. Confirm by reading `validate_bundle` that it iterates only the required list, so a stale `rofi.rasi` stays valid.
- **Acceptance criteria:** Required fragments are `hyprland.conf hyprland.lua waybar.css ghostty.conf`; a bundle carrying a stale `rofi.rasi` still validates.
- **Verification:** The suite's fixtures keep writing a stale `rofi.rasi` and every scenario passes.

- [x] **T2: Delete the 12 Rofi fragments** — 108 lines deleted, 12 files
- **Files:** `home/.local/share/moonarch/themes/*/rofi.rasi`
- **Description:** Delete the fragment from each real bundle. Do not dereference or remove the `current` symlink, which aliases `tokyo-night` and makes a glob report 13 paths for 12 files.
- **Acceptance criteria:** No `rofi.rasi` remains; `current` still resolves to `tokyo-night`.
- **Verification:** `ls home/.local/share/moonarch/themes/*/rofi.rasi` reports nothing; `readlink` on `current` is unchanged.

- [x] **T3: Move the interactive path to Selene** — 5 lines changed
- **File:** `home/.local/bin/moonarch/theme-selector`
- **Description:** Replace the Rofi `-dmenu` pipeline with `qs -c selene ipc call selene openThemes`. Capture nothing on stdout, reimplement no selection logic, and exit non-zero with a message naming `--list` and `--apply` when Quickshell is unavailable.
- **Acceptance criteria:** The path invokes the Selene IPC method and fails loudly without Quickshell.
- **Verification:** Two suite scenarios: the delegation logs the IPC call and leaves `current` unchanged, and a failing `qs` produces a non-zero exit with a naming message.

- [x] **T4: Replace the selector suite's Rofi machinery** — ~70 lines changed
- **File:** `tests/moonarch-theme-selector_test.sh`
- **Description:** Remove the `ROFI_*` fixtures, the fake launcher and the cancellation scenario. Add the delegation and failure scenarios. Retarget the missing-fragment scenario to `ghostty.conf`, since `rofi.rasi` is gone. Convert picker-driven scenarios to the positional form.
- **Acceptance criteria:** The Selene binding assertion, the autostart guard and the retired-tool guard stay byte-identical; the suite passes.
- **Verification:** `git diff` on the file shows the intended lines only; the suite passes.

- [x] **T5: Widen the retired-tool guard** — 1 line changed
- **File:** `tests/moonarch-theme-selector_test.sh`
- **Description:** Extend the guard to reject `rofi` alongside `eww` and `dunst`, using a word-boundary match so `profile` and `accel_profile` do not false-positive.
- **Acceptance criteria:** A `rofi` reference under `home/` fails the suite.
- **Verification:** `grep -rIiqw --exclude-dir=selene rofi home/` returns nothing.

- [x] **T6: Drop the Rofi assertions from the palette contract** — 53 lines changed
- **File:** `tests/moonarch-theme-palette_test.sh`
- **Description:** Remove `rofi.rasi` from the protected paths, files, hashes and required files, delete `fragment_rasi_value`, and remove the four per-bundle Rofi mappings. Keep everything else.
- **Acceptance criteria:** Every non-Rofi assertion survives and the suite passes.
- **Verification:** `bash tests/moonarch-theme-palette_test.sh`.

- [x] **T7: Stop installing and offering Rofi** — 3 lines changed
- **Files:** `cli/pkg/installer/catalog.go`, `cli/pkg/installer/ui/menu/data.go`, `cli/pkg/installer/catalog_menu_test.go`
- **Description:** Remove `rofi` from the `hyprland` group and the TUI menu, and narrow the fallback expectation to `dunst`.
- **Acceptance criteria:** `rofi` appears in neither side and the agreement test passes.
- **Verification:** `go test ./...` in `cli/`.

- [x] **T8: Stop documenting Rofi** — ~8 lines changed
- **Files:** `README.md`, `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/bug_report.yml`, `.github/ISSUE_TEMPLATE/feature_request.yml`, `openspec/config.yaml`
- **Description:** Drop the Rofi prerequisite, correct the picker sentence, remove the directory-tree row and the commit scope, remove the issue-template component, and update the project context.
- **Acceptance criteria:** No document offers Rofi or claims it is the picker.
- **Verification:** A tree-versus-reality check and a grep for `rofi`.

- [x] **T9: Sync the two capability requirements** — spec delta
- **File:** `openspec/changes/retire-rofi/specs/moonarch-theme-selector/spec.md`
- **Description:** Requirement 1 counted "four supported consumers" and requirement 3 listed Rofi among the supported fragments. Both now describe three consumers: Hyprland, the Waybar fragment shared with Selene, and Ghostty.
- **Acceptance criteria:** The spec names no retired tool in its requirements.
- **Verification:** `openspec validate retire-rofi --type change --strict`, then `openspec validate --specs`.

- [x] **T10: Run the full gate** — verification
- **Description:** Both suites, `test.sh` including Docker Stow, and the Go suite.
- **Acceptance criteria:** All green.
- **Verification:** Recorded in `verify-report.md`.

---

## Execution Notes

**Ordering constraint:** T1 must precede T2, or an intermediate commit has the selector requiring a fragment that no longer exists. T3 must precede T4, or the new scenarios test behaviour that is not there yet.

**Strict TDD considerations:** the delegation was written test-first and the RED run is worth reading: it failed with `no-argument path did not open the Selene theme picker`, and it also exposed the silent-failure mode the old path had, exiting 0 with its launcher missing. The root project has `strict_tdd: false`; the `cli/` subproject has it true and its existing agreement test covers T7.

**Coverage note:** T6 removes real assertions and T4 rewrites scenarios. Both are accounted for in the verify report, which lists what was removed and what was preserved.
