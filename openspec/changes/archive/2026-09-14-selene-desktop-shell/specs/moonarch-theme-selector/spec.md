# Delta for MoonArch Theme Selector

## MODIFIED Requirements

### Requirement: Name-Only Validated Atomic Switching

The selector MUST accept only a bundle name, reject invalid identities and resolved paths outside the themes root, and MUST NOT mutate bundle contents. It SHALL atomically replace only `current` after validation, reload supported running consumers, and restore the prior link if a reload fails. The interactive picker SHALL be provided by Selene: the `Super+Shift+T` binding invokes `qs -c selene ipc call selene openThemes`, and the picker SHALL offer candidates through `theme-selector --list` and apply the chosen identity through `theme-selector --apply`. The `--list`, `--apply`, and name-only invocations MUST NOT require Selene to be running.

#### Scenario: Valid selection switches all consumers

- GIVEN a valid named bundle and an existing active theme
- WHEN the user selects that name through the Selene picker or applies it by name
- THEN `current` SHALL atomically point to the selected bundle
- AND Hyprland, Waybar, and Selene SHALL reload when running; Ghostty SHALL apply on new terminals

#### Scenario: Unsafe or failed selection preserves active theme

- GIVEN an invalid name, escaping path, or reload failure
- WHEN selection is attempted
- THEN `current` SHALL remain or be restored to its prior link
- AND no partial or invalid bundle SHALL become active

### Requirement: Bounded Runtime Scope

The system SHALL support only Hyprland, Waybar, Rofi, and Ghostty fragments in this slice. The Waybar fragment SHALL additionally serve Selene, which derives its tokens from `waybar.css` and `ghostty.conf` and MUST NOT require a fragment of its own. It MUST NOT provide wallpaper, theme previews, GTK, Qt, Yazi, multi-theme bundles, a general theme engine, extensions to `dots theme`, or runtime selection in installer UI.

#### Scenario: Unsupported request is excluded

- GIVEN a user requests an excluded integration or installer-UI selection
- WHEN this capability is used or documented
- THEN no such behavior SHALL be offered
