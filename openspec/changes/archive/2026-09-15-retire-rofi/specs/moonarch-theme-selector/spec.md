# Delta for MoonArch Theme Selector

## MODIFIED Requirements

### Requirement: Tokyo Night Is the Initial Valid Theme

The system MUST provide a versioned `tokyo-night` bundle under the MoonArch themes root. A fresh installation SHALL provide `themes/current` as a valid relative link to that bundle. A bundle MUST contain a valid identity/manifest and required fragments for all three supported consumers.

#### Scenario: Fresh installation selects Tokyo Night

- GIVEN MoonArch is installed into a previously unconfigured home
- WHEN installation completes successfully
- THEN `themes/current` SHALL resolve to the `tokyo-night` bundle
- AND all three consumer fragments SHALL be available

#### Scenario: Incomplete bundle is not valid

- GIVEN a candidate bundle lacks its manifest or a required consumer fragment
- WHEN the selector validates the bundle
- THEN it SHALL reject the bundle without changing `current`

### Requirement: Bounded Runtime Scope

The system SHALL support only Hyprland, Waybar, and Ghostty fragments in this slice. The Waybar fragment SHALL additionally serve Selene, which derives its tokens from `waybar.css` and `ghostty.conf` and MUST NOT require a fragment of its own. It MUST NOT provide wallpaper, theme previews, GTK, Qt, Yazi, multi-theme bundles, a general theme engine, extensions to `dots theme`, or runtime selection in installer UI.

#### Scenario: Unsupported request is excluded

- GIVEN a user requests an excluded integration or installer-UI selection
- WHEN this capability is used or documented
- THEN no such behavior SHALL be offered
