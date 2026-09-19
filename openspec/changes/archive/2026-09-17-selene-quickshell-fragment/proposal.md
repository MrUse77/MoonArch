# Introduce the Quickshell bundle fragment (quickshell.json) for Selene

## Why

Selene derives its colour tokens from the theme bundles, but the fragment it
reads is named after a retired tool: `Services/Theme.qml` parses
`.../current/waybar.css` (four colour aliases) plus `ghostty.conf` (palette,
background, foreground) and applies an override hook that is already wired for
a dedicated fragment that does not exist in any bundle yet:

```qml
// Hook de integración oficial moonarch: un fragmento dedicado por
// bundle (quickshell.json con nombres de token idénticos) tiene
// prioridad total sobre la derivación. Todavía no existe en ningún
// bundle; onLoadFailed lo deja sin efecto.
```

Two problems follow from that state:

1. **The bundle contract keeps a dead tool's name for live data.** `waybar.css`
   was kept when Waybar retired precisely because Selene derives from it; the
   palette contract still asserts four `@define-color` aliases per bundle as
   Selene's colour source. Deprecating `waybar.css` is blocked until Selene has
   a fragment of its own.
2. **The Ghostty palette never reaches the shell.** Every bundle writes
   `palette = N=#hex`, but Theme.qml's parser only recognises `palette N=#hex`
   keys. The `g.pN` entries are therefore undefined at runtime and the shell
   silently falls back to the embedded Tokyo Night values for `success`,
   `warning`, `purple`, `cyan`, `gray` and `surface` on every bundle. Only
   Tokyo Night happens to match its fallback.

This change executes the moonarch-integration roadmap recorded in Selene's own
proposal: "incorporación a moonarch vía fragmento `quickshell.json` por bundle
+ alta en `required_files`".

## What Changes

- **Added**: `quickshell.json` to all 12 theme bundles — a versioned fragment
  (keys in identical tokens to Theme.qml) carrying the thirteen Selene colour
  tokens `bg`, `bgDeep`, `surface`, `surfaceBright`, `text`, `textDim`,
  `accent`, `urgent`, `success`, `warning`, `purple`, `cyan`, `gray` as
  lowercase `#rrggbb` strings. Values are derived from each bundle's own
  `waybar.css` and `ghostty.conf` with the exact formula Theme.qml applies, so
  the active theme's visuals do not change and every other bundle finally
  receives its real palette.
- **Changed**: `home/.local/bin/moonarch/theme-selector` — `quickshell.json`
  joins `required_files`, so bundle validation requires it.
- **Changed**: `tests/moonarch-theme-palette_test.sh` — the bundle contract
  requires the fragment, binds all thirteen tokens to the bundle's own
  `waybar.css`/`ghostty.conf` values (including the three derived `mix()`
  tokens), and pins the new Tokyo Night fragment by hash.
- **Changed**: `tests/moonarch-theme-selector_test.sh` — bundle fixtures gain
  the fragment, a missing-fragment rejection case is added, and the
  retired-stack sweep excludes submodule worktrees (nix lock hashes can match
  `eww`/`dunst`/`rofi` case-insensitively, a pre-existing false positive that
  depends on submodule init state).
- **Changed**: `openspec/specs/moonarch-theme-selector/spec.md` — Selene is a
  first-class consumer with its own fragment; the "MUST NOT require a fragment
  of its own" clause is replaced by the fragment contract.
- **Changed**: `README.md` and `openspec/config.yaml` — the stack note now
  names `quickshell.json` as Selene's fragment and `waybar.css` as the pending
  deprecation.

## Scope

### In scope

- The fragment itself: schema, generation, values for the 12 bundles.
- Bundle validation in `theme-selector` (`required_files`).
- Palette-contract coverage for the fragment, including the Tokyo Night hash
  pin.
- Selector-suite fixtures and the missing-fragment rejection scenario.
- Capability delta for `moonarch-theme-selector`.
- Documentation of the fragment contract and the deprecation path.

### Out of scope

- **Deleting the 12 `waybar.css` bundle fragments.** They remain required and
  back Selene's fallback derivation while the deprecated name still exists;
  removal is a follow-up change once this fragment is established.
- **Editing Selene's `Services/Theme.qml`** (submodule). The override hook this
  fragment needs is already published at the pinned commit; the submodule is
  not touched. A future upstream change can make `quickshell.json` the primary
  source when `waybar.css` is removed.
- **The Waybar reload branch in `theme-selector`** (`pgrep -x waybar` /
  `pkill -SIGUSR2 waybar`). Inert when Waybar is absent, unchanged here.
- **`ghostty.conf` fragments.** Still required for Ghostty and for the
  fallback derivation; the palette contract keeps asserting them.
- **Installer or CLI changes.** The bundles are installed as release content;
  `cli/` already ships the themes tree unchanged.

## Affected areas

| Area | Expected change |
| --- | --- |
| `home/.local/share/moonarch/themes/*/quickshell.json` | New: 12 fragments, one per bundle. |
| `home/.local/bin/moonarch/theme-selector` | One array literal gains `quickshell.json`. |
| `tests/moonarch-theme-palette_test.sh` | `required_files` extended; per-bundle fragment assertions (13 tokens + version); Tokyo Night protected set and hash extended. |
| `tests/moonarch-theme-selector_test.sh` | `make_bundle` fixtures gain the fragment; one new rejection case; retired-stack sweep excludes submodule worktrees. |
| `openspec/specs/moonarch-theme-selector/spec.md` | Two requirements modified (four consumers; fragment contract). |
| `README.md` | Stack note names the new fragment and the deprecation path. |
| `openspec/config.yaml` | Context block reworded accordingly. |

## Benefits

- Selene reads a fragment named after the tool that actually runs it, and the
  `waybar.css` deprecation finally has a paved path: remove the fragment and
  the fallback code together, as a follow-up.
- The active theme's exact visuals are preserved (Tokyo Night values match the
  current runtime derivation token for token).
- The other 11 bundles stop silently using Tokyo Night's `success`, `warning`,
  `purple`, `cyan`, `gray` and `surface`: they switch to their own palettes the
  moment a fragment exists — a correction, not a style change.
- The palette contract asserts the fragment against the bundle's own fragments
  with the same `mix()` formula Theme.qml uses, so the fragment cannot drift
  from what the bundle declares.
- Bundle validation in `theme-selector` rejects a bundle without the fragment,
  so `current` can never point at a bundle Selene cannot fully theme.

## Trade-offs

- Bundle authors now maintain a third data fragment (5 files per bundle).
- The fragment freezes derived values (`mix()` output) instead of source
  colours, duplicating derivable data; the contract test is the guard against
  drift.
- The palette test grows another awk block (the `mix()` reimplementation) to
  bind the derived tokens.
- Non-Tokyo themes change appearance at runtime on the next theme switch,
  because their real palette replaces the Tokyo fallback (see Risks).

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| A visual surprise when switching to a non-Tokyo bundle (real palette replaces the Tokyo fallback for six tokens). | Called out explicitly here and in the verify report; it is the intended correction and the fragment values are bound to the bundle's own fragments by the palette contract. |
| The fragment drifts from the bundle's `waybar.css`/`ghostty.conf` values. | The palette contract recomputes every token — including the `mix()`-derived ones — from the bundle's own fragments and fails on any mismatch. |
| A malformed fragment silently falls back to old derivation (Theme.qml ignores JSON parse errors). | The contract test requires the version marker, the exact token set and the `#rrggbb` shape per line. |
| The Tokyo Night pin set grows and one more file must never change. | Existing pin machinery extended: protected path + blob-hash assertion. |
| `theme-selector` rejects bundles missing the fragment, breaking previously valid bundles. | Only this repository's bundles exist; all 12 gain the fragment in this same change. |

## Rollback

Configuration-only, through Git. Reverting this change removes the 12
fragments, drops `quickshell.json` from `required_files` and restores the spec.
Selene falls back to the current `waybar.css`/`ghostty.conf` derivation exactly
as before, including the palette parse miss for non-Tokyo bundles.

## Success criteria

- All 12 bundles contain a `quickshell.json` fragment; `current` still resolves
  to `tokyo-night`.
- `theme-selector` validates a bundle without `quickshell.json` as invalid and
  leaves `current` untouched.
- `tests/moonarch-theme-palette_test.sh` binds the 13 fragment tokens of every
  bundle to its `waybar.css`/`ghostty.conf` values with the Theme.qml formula,
  and pins the Tokyo Night fragment by hash.
- `bash test.sh` passes end to end (palette contract, selector contract,
  Docker Stow validation).
- `openspec/specs/moonarch-theme-selector/spec.md` names four consumer
  fragments and the `quickshell.json` token contract.
- No file outside the bundles, the selector, the tests and the docs changes;
  the Selene submodule pin is untouched.