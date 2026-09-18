# Design: the Quickshell bundle fragment (quickshell.json) for Selene

## Decision summary

| Decision | Choice | Rationale |
| --- | --- | --- |
| Fragment name | `quickshell.json` | Names the consumer that runs the shell (Quickshell reading the Selene config), the name the Selene roadmap recorded. Quickshell's own config resolution reads `<config dir>/<name>/shell.qml` and has no `quickshell.json` of its own, so the name is free for MoonArch's bundle contract. |
| Fragment schema | Flat JSON object: `version` + the 13 Theme.qml token names | Theme.qml's override hook applies exactly the keys present in its internal token object (`if (k in _t) _t[k] = _lastOverride[k]`); unknown keys are inert. A flat object with identical names is the only shape the published hook consumes. |
| Values | Derived per bundle with Theme.qml's exact formula, sourced from the bundle's own `waybar.css` and `ghostty.conf` | Keeps the active theme pixel-identical and makes the fragment a frozen, contract-testable snapshot. |
| `waybar.css` fate | Kept, still required, demoted to fallback | Deprecation is a follow-up; removing it now would invalidate every bundle if the fragment were ever reverted, and the spec keeps the fallback contract explicit. |
| Theme.qml (submodule) | Untouched | The override hook this fragment activates is already published at the pinned commit `cf42315`. |
| Contract enforcement | Palette test recomputes every token from the bundle's own fragments | The test becomes the guard that the fragment cannot drift from `waybar.css`/`ghostty.conf`, replicating the `mix()` formula in awk. |

## The fragment contract

```json
{
  "version": 1,
  "bg": "#1a1b26",
  "bgDeep": "#111219",
  "surface": "#26293b",
  "surfaceBright": "#272937",
  "text": "#c0caf5",
  "textDim": "#707692",
  "accent": "#7aa2f7",
  "urgent": "#f7768e",
  "success": "#9ece6a",
  "warning": "#e0af68",
  "purple": "#bb9af7",
  "cyan": "#7dcfff",
  "gray": "#414868"
}
```

- `version` is a contract marker for future schema evolution. Theme.qml ignores
  it (not a token key), the palette contract asserts it.
- The 13 tokens are exactly the keys Theme.qml's override hook applies; any
  other key is ignored at runtime and must not be added without a theme-system
  delta.
- Colours are lowercase `#rrggbb`, hex-digit counts fixed to six.
- Runtime priority: derivation from `waybar.css`/`ghostty.conf` runs first,
  then every token present in the fragment replaces the derived value. The
  fragment therefore wins over both fragments unconditionally.

## Derivation formula (replicates Services/Theme.qml)

Sources per bundle:

| Token | Source | Fallback |
| --- | --- | --- |
| `bg` | `waybar.css` `bg_dark` | `ghostty.conf` `background` |
| `text` | `waybar.css` `text_main` | `ghostty.conf` `foreground` |
| `accent` | `waybar.css` `accent_blue` | `ghostty.conf` palette 4 |
| `urgent` | `waybar.css` `urgent_red` | `ghostty.conf` palette 1 |
| `success`, `warning`, `purple`, `cyan`, `gray` | `ghostty.conf` palette 2, 3, 5, 6, 8 | Tokyo Night preset |
| `bgDeep`, `surface`, `surfaceBright`, `textDim` | `mix()`, see below | — |

`mix(hexA, hexB, t)` — exactly as Theme.qml:

- channels to 0..1 (`parseInt(hex, 16) / 255`),
- `c = a + (b - a) * t` per channel,
- clamp to 0..1, `Math.round(c * 255)` (half up), lowercase two-digit hex.

Derived tokens:

| Token | Formula |
| --- | --- |
| `bgDeep` | `mix(bg, #000000, 0.35)` |
| `surface` | `mix(bg, palette8, 0.32)` |
| `surfaceBright` | `mix(bg, foreground, 0.08)` |
| `textDim` | `mix(text, bg, 0.48)` |

Order matters and is replicated from the QML: `surfaceBright` reads Ghostty's
`foreground` directly (not the derived `text`), and `textDim` derives from the
already-assigned `text`.

## The Ghostty palette parse miss (why the fragment also corrects)

Theme.qml's `parseGhostty` only maps a palette entry when the key matches
`^palette\s+(\d+)$`, i.e. the `palette N=#hex` syntax. Every bundle in this
repository writes `palette = N=#hex`, where the key is `palette` and the value
is `N=#hex`; the regex never matches, so `g.p0..g.p15` are always undefined at
runtime.

Consequences at runtime today:

| Token | Bundle declares | Shell renders |
| --- | --- | --- |
| `success`, `warning`, `purple`, `cyan` | per-bundle palette 2/3/5/6 | Tokyo Night preset |
| `gray`, `surface` | per-bundle palette 8 | Tokyo Night preset |

Tokyo Night is immune only because its own values equal the preset. The
fragment generation parses the bundle format the files actually use (both
spellings), so the fragment freezes the *declared* palette; from the moment a
fragment exists, the shell renders what the bundle declares. This is the
intended correction described in the proposal.

## Before / after

| | Before | After |
| --- | --- | --- |
| Selene token source | `waybar.css` (4 aliases) + `ghostty.conf` (palette path effectively dead) | `quickshell.json` wins; `waybar.css` + `ghostty.conf` back the fallback |
| Bundle validity (`theme-selector`) | 5 files: `manifest.toml`, `hyprland.conf`, `hyprland.lua`, `waybar.css`, `ghostty.conf` | 6 files, `quickshell.json` required |
| Bundle contents | 5 files | 6 files |
| Spec | "three supported consumers"; Selene "MUST NOT require a fragment of its own" | four consumers; `quickshell.json` token contract |
| Tokyo Night protected set | 5 paths with blob hashes | 6 paths with blob hashes |

## Palette-contract assertions added

Per bundle, the test extracts each of the 14 keys from `quickshell.json` and
asserts:

- `version == 1`;
- `bg`, `text`, `accent`, `urgent` equal the bundle's `waybar.css` aliases
  (normalized);
- `success`, `warning`, `purple`, `cyan`, `gray` equal the bundle's
  `ghostty.conf` palette 2, 3, 5, 6, 8;
- `bgDeep`, `surface`, `surfaceBright`, `textDim` equal `mix()` of the bundle's
  own values per the table above, recomputed in awk.

The Tokyo Night fragment additionally joins `protected_paths`,
`protected_files` and the blob-hash map.

## Selector-suite fixtures

`make_bundle` writes a `quickshell.json` fixture (`{"version": 1}`), so every
existing case keeps its bundle valid, and a new case removes the fragment and
asserts `theme-selector` rejects the bundle while preserving `current`.

## Verification plan

- `bash tests/moonarch-theme-palette_test.sh` — fragment assertions + pins.
- `bash tests/moonarch-theme-selector_test.sh` — fixtures + new rejection case.
- `bash test.sh` — palette contract, selector contract, Docker Stow validation.
- Manual spot check: the Tokyo Night fragment values equal the runtime
  derivation (verified during generation line by line).

## Rollout and rollback

The bundles are installed as release content; the new fragment lands with the
next configuration release. No runtime transition is needed: Theme.qml's poll
picks up the fragment without a restart, and `themeReload` refreshes instantly.

Rollback is `git revert` of this change; Selene falls back to the previous
derivation (including the palette parse miss) without further action.