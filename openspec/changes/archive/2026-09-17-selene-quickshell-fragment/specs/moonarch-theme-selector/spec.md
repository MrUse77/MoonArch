# Delta for MoonArch Theme Selector

## MODIFIED Requirements

### Requirement: Tokyo Night Is the Initial Valid Theme

The system MUST provide a versioned `tokyo-night` bundle under the MoonArch themes root. A fresh installation SHALL provide `themes/current` as a valid relative link to that bundle. A bundle MUST contain a valid identity/manifest and required fragments for all four supported consumers.

#### Scenario: Fresh installation selects Tokyo Night

- GIVEN MoonArch is installed into a previously unconfigured home
- WHEN installation completes successfully
- THEN `themes/current` SHALL resolve to the `tokyo-night` bundle
- AND all four consumer fragments SHALL be available

#### Scenario: Incomplete bundle is not valid

- GIVEN a candidate bundle lacks its manifest or a required consumer fragment
- WHEN the selector validates the bundle
- THEN it SHALL reject the bundle without changing `current`

### Requirement: Bounded Runtime Scope

The system SHALL support only Hyprland, Waybar, Ghostty, and Quickshell fragments in this slice. Selene SHALL apply the `quickshell.json` fragment tokens with priority over the `waybar.css` and `ghostty.conf` derivation. The fragment SHALL be a single JSON object carrying a `version` marker and the thirteen Selene colour tokens (`bg`, `bgDeep`, `surface`, `surfaceBright`, `text`, `textDim`, `accent`, `urgent`, `success`, `warning`, `purple`, `cyan`, `gray`) as lowercase `#rrggbb` strings; keys outside that set SHALL be ignored. The `waybar.css` fragment SHALL remain a required consumer fragment backing the fallback derivation while the deprecation of its name is pending. It MUST NOT provide wallpaper, theme previews, GTK, Qt, Yazi, multi-theme bundles, a general theme engine, extensions to `dots theme`, or runtime selection in installer UI.

#### Scenario: Unsupported request is excluded

- GIVEN a user requests an excluded integration or installer-UI selection
- WHEN this capability is used or documented
- THEN no such behavior SHALL be offered