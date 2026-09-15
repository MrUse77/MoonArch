#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
selector="${THEME_SELECTOR:-$repo_root/home/.local/bin/moonarch/theme-selector}"

pass_count=0

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_eq() {
    [[ "$1" == "$2" ]] || fail "expected '$2', got '$1'"
}

assert_success() {
    "$@" || fail "command failed: $*"
}

assert_failure() {
    if "$@"; then
        fail "command unexpectedly succeeded: $*"
    fi
}

new_case() {
    case_dir="$(mktemp -d)"
    themes="$case_dir/themes"
    fake_bin="$case_dir/bin"
    command_log="$case_dir/commands.log"
    rofi_input="$case_dir/rofi-input"
    test_home="$case_dir/home"
    mkdir -p "$themes" "$fake_bin" "$test_home/.config/rofi/scripts"
    : > "$command_log"

    cat > "$test_home/.config/rofi/scripts/launch" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'rofi %s\n' "$*" >> "$COMMAND_LOG"
cat > "$ROFI_INPUT"
[[ "${ROFI_CANCEL:-0}" == 1 ]] && exit 1
printf '%s\n' "${ROFI_OUTPUT:-}"
EOF
    cat > "$fake_bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'hyprctl %s\n' "$*" >> "$COMMAND_LOG"
[[ "${HYPRCTL_FAIL:-0}" != 1 ]]
EOF
    cat > "$fake_bin/pgrep" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'pgrep %s\n' "$*" >> "$COMMAND_LOG"
[[ "${WAYBAR_RUNNING:-0}" == 1 ]]
EOF
    cat > "$fake_bin/pkill" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'pkill %s\n' "$*" >> "$COMMAND_LOG"
[[ "${PKILL_FAIL:-0}" != 1 ]]
EOF
    cat > "$fake_bin/qs" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'qs %s\n' "$*" >> "$COMMAND_LOG"
[[ "${QS_FAIL:-0}" != 1 ]]
EOF
    chmod +x "$fake_bin"/* "$test_home/.config/rofi/scripts/launch"
}

make_bundle() {
    local id="$1"
    local bundle="$themes/$id"
    mkdir -p "$bundle"
    printf 'id = "%s"\n' "$id" > "$bundle/manifest.toml"
    printf '# hyprland %s\n' "$id" > "$bundle/hyprland.conf"
    printf 'return {}\n' > "$bundle/hyprland.lua"
    printf '/* waybar %s */\n' "$id" > "$bundle/waybar.css"
    printf '/* rofi %s */\n' "$id" > "$bundle/rofi.rasi"
    printf '# ghostty %s\n' "$id" > "$bundle/ghostty.conf"
}

run_selector() {
    env \
        MOONARCH_THEMES_ROOT="$themes" \
        HOME="$test_home" \
        PATH="$fake_bin:$PATH" \
        COMMAND_LOG="$command_log" \
        ROFI_INPUT="$rofi_input" \
        "$selector" "$@"
}

assert_current() {
    assert_eq "$(readlink "$themes/current")" "$1"
}

preserves_current_on_failure() {
    local description="$1"
    shift
    new_case
    make_bundle tokyo-night
    ln -s tokyo-night "$themes/current"
    assert_failure "$@"
    assert_current tokyo-night
    printf 'PASS: %s\n' "$description"
    pass_count=$((pass_count + 1))
}

new_case
make_bundle tokyo-night
make_bundle alpha
mkdir -p "$themes/Bad"
ln -s tokyo-night "$themes/current"
list_output="$(run_selector --list)" || fail '--list failed'
assert_eq "$list_output" $'alpha\ntokyo-night'
assert_current tokyo-night
[[ ! -s "$command_log" ]] || fail '--list invoked a consumer command'
printf 'PASS: --list prints sorted valid IDs without side effects\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
make_bundle alpha
ln -s tokyo-night "$themes/current"
assert_success run_selector --apply alpha
assert_current alpha
if grep -q '^rofi ' "$command_log"; then
    fail '--apply invoked Rofi'
fi
grep -qx 'qs -c selene ipc call selene themeReload' "$command_log" || fail 'Selene reload argv differs'
printf 'PASS: --apply switches directly and refreshes Selene\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
make_bundle alpha
ln -s tokyo-night "$themes/current"
assert_success env QS_FAIL=1 MOONARCH_THEMES_ROOT="$themes" HOME="$test_home" PATH="$fake_bin:$PATH" COMMAND_LOG="$command_log" ROFI_INPUT="$rofi_input" "$selector" alpha
assert_current alpha
if grep -q '^rofi ' "$command_log"; then
    fail 'legacy positional apply invoked Rofi'
fi
grep -qx 'qs -c selene ipc call selene themeReload' "$command_log" || fail 'legacy positional apply skipped Selene refresh'
printf 'PASS: positional apply survives Selene refresh failure\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
make_bundle alpha
ln -s tokyo-night "$themes/current"
rm "$fake_bin/qs"
assert_success run_selector --apply alpha
assert_current alpha
printf 'PASS: --apply does not require Quickshell\n'
pass_count=$((pass_count + 1))

for malformed in '--list extra' '--apply' '--apply alpha extra' '--apply --unknown' 'alpha beta' '--unknown'; do
    new_case
    make_bundle alpha
    read -r -a malformed_args <<< "$malformed"
    error_output="$case_dir/error"
    if run_selector "${malformed_args[@]}" 2>"$error_output"; then
        fail "malformed arguments succeeded: $malformed"
    else
        status=$?
    fi
    assert_eq "$status" '2'
    grep -Fq 'usage:' "$error_output" || fail "malformed arguments lacked usage text: $malformed"
done
printf 'PASS: malformed arguments and options exit 2 with usage\n'
pass_count=$((pass_count + 1))

preserves_current_on_failure "invalid IDs are rejected" run_selector '../escape'

new_case
make_bundle tokyo-night
ln -s tokyo-night "$themes/current"
rm "$themes/tokyo-night/manifest.toml"
assert_failure run_selector tokyo-night
assert_current tokyo-night
printf 'PASS: missing manifest is rejected\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
ln -s tokyo-night "$themes/current"
printf 'id = "wrong"\n' > "$themes/tokyo-night/manifest.toml"
assert_failure run_selector tokyo-night
assert_current tokyo-night
printf 'PASS: mismatched manifest is rejected\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
ln -s tokyo-night "$themes/current"
rm "$themes/tokyo-night/rofi.rasi"
assert_failure run_selector tokyo-night
assert_current tokyo-night
printf 'PASS: missing fragment is rejected\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
ln -s tokyo-night "$themes/current"
rm "$themes/tokyo-night/hyprland.lua"
assert_failure run_selector tokyo-night
assert_current tokyo-night
printf 'PASS: missing Hyprland Lua fragment is rejected\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
ln -s tokyo-night "$themes/current"
outside="$case_dir/outside.conf"
printf 'outside\n' > "$outside"
rm "$themes/tokyo-night/hyprland.conf"
ln -s "$outside" "$themes/tokyo-night/hyprland.conf"
assert_failure run_selector tokyo-night
assert_current tokyo-night
printf 'PASS: escaped fragment symlink is rejected\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
ln -s tokyo-night "$themes/current"
outside="$case_dir/outside.lua"
printf 'return {}\n' > "$outside"
rm "$themes/tokyo-night/hyprland.lua"
ln -s "$outside" "$themes/tokyo-night/hyprland.lua"
assert_failure run_selector tokyo-night
assert_current tokyo-night
printf 'PASS: escaped Hyprland Lua symlink is rejected\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
printf 'not a link\n' > "$themes/current"
assert_failure run_selector tokyo-night
[[ -f "$themes/current" ]] || fail 'non-symlink current was mutated'
printf 'PASS: non-symlink current is rejected\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
ln -s "$themes/tokyo-night" "$themes/current"
assert_failure run_selector tokyo-night
assert_eq "$(readlink "$themes/current")" "$themes/tokyo-night"
printf 'PASS: absolute current is rejected\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
ln -s tokyo-night "$themes/current"
assert_success env ROFI_CANCEL=1 MOONARCH_THEMES_ROOT="$themes" HOME="$test_home" PATH="$fake_bin:$PATH" COMMAND_LOG="$command_log" ROFI_INPUT="$rofi_input" "$selector"
assert_current tokyo-night
if grep -Eq '^(hyprctl|pgrep|pkill) ' "$command_log"; then
    fail 'cancellation ran a reload command'
fi
printf 'PASS: Rofi cancellation is a no-op\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
make_bundle alpha
ln -s tokyo-night "$themes/current"
bundle_digest_before="$(sha256sum "$themes"/tokyo-night/* "$themes"/alpha/*)"
assert_success env ROFI_OUTPUT=alpha MOONARCH_THEMES_ROOT="$themes" HOME="$test_home" PATH="$fake_bin:$PATH" COMMAND_LOG="$command_log" ROFI_INPUT="$rofi_input" WAYBAR_RUNNING=0 "$selector"
assert_current alpha
assert_eq "$(cat "$rofi_input")" $'alpha\ntokyo-night'
bundle_digest_after="$(sha256sum "$themes"/tokyo-night/* "$themes"/alpha/*)"
assert_eq "$bundle_digest_after" "$bundle_digest_before"
grep -qx 'hyprctl reload' "$command_log" || fail 'Hyprland reload argv differs'
grep -qx 'pgrep -x waybar' "$command_log" || fail 'Waybar process check argv differs'
grep -q '^rofi -dmenu -p Theme -no-custom ' "$command_log" || fail 'Rofi argv differs'
grep -qx 'qs -c selene ipc call selene themeReload' "$command_log" || fail 'successful selection skipped Selene refresh'
if grep -Eq 'ghostty|rofi.*reload' "$command_log"; then
    fail 'selector invoked an unsupported Rofi or Ghostty reload'
fi
if compgen -G "${themes}/.current*" >/dev/null; then
    fail 'atomic switch left a temporary link'
fi
printf 'PASS: sorted selection atomically switches with fixed commands\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
make_bundle alpha
ln -s tokyo-night "$themes/current"
assert_failure env HYPRCTL_FAIL=1 ROFI_OUTPUT=alpha MOONARCH_THEMES_ROOT="$themes" HOME="$test_home" PATH="$fake_bin:$PATH" COMMAND_LOG="$command_log" ROFI_INPUT="$rofi_input" WAYBAR_RUNNING=0 "$selector"
assert_current tokyo-night
grep -c '^hyprctl reload$' "$command_log" | grep -qx '2' || fail 'rollback did not retry Hyprland reload'
grep -c '^qs -c selene ipc call selene themeReload$' "$command_log" | grep -qx '1' || fail 'rollback refresh skipped Selene reload'
printf 'PASS: reload failure restores prior link\n'
pass_count=$((pass_count + 1))

new_case
make_bundle tokyo-night
make_bundle alpha
ln -s tokyo-night "$themes/current"
assert_failure env PKILL_FAIL=1 ROFI_OUTPUT=alpha MOONARCH_THEMES_ROOT="$themes" HOME="$test_home" PATH="$fake_bin:$PATH" COMMAND_LOG="$command_log" ROFI_INPUT="$rofi_input" WAYBAR_RUNNING=1 "$selector"
assert_current tokyo-night
grep -c '^pkill -SIGUSR2 waybar$' "$command_log" | grep -qx '2' || fail 'rollback did not retry Waybar reload'
grep -c '^qs -c selene ipc call selene themeReload$' "$command_log" | grep -qx '1' || fail 'Waybar rollback refresh skipped Selene reload'
printf 'PASS: Waybar reload failure restores prior link\n'
pass_count=$((pass_count + 1))

grep -Fqx 'local theme_path = os.getenv("HOME") .. "/.local/share/moonarch/themes/current/hyprland.lua"' "$repo_root/home/.config/hypr/hyprland.lua" || fail 'Hyprland Lua does not select the current theme fragment'
grep -Fq 'pcall(dofile, theme_path)' "$repo_root/home/.config/hypr/hyprland.lua" || fail 'Hyprland Lua does not load the selected theme fragment'
grep -Fq 'hl.config(theme_config)' "$repo_root/home/.config/hypr/hyprland.lua" || fail 'Hyprland Lua does not apply the selected theme fragment'
grep -Fq 'hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(seleneIpc .. "openThemes"))' "$repo_root/home/.config/hypr/hyprland.lua" || fail 'Hyprland Lua selector binding is missing'
grep -Fq 'qs -c selene' "$repo_root/home/.config/hypr/hyprland.lua" || fail 'Hyprland autostart does not launch Selene'
autostart_block="$(sed -n '/hl.on("hyprland.start"/,/^end)/p' "$repo_root/home/.config/hypr/hyprland.lua")"
if grep -Eqw '(waybar|dunst|eww)' <<<"$autostart_block"; then
    fail 'Hyprland autostart starts a replaced bar, notification daemon, or widget host next to Selene'
fi
if grep -rIiq --exclude-dir=selene -e eww -e dunst "$repo_root/home"; then
    fail 'A tracked configuration still references a retired widget host or notification daemon'
fi
grep -Fqx '@import url("../../.local/share/moonarch/themes/current/waybar.css");' "$repo_root/home/.config/waybar/style.css" || fail 'Waybar does not import the current theme'
grep -Fqx 'config-file = "~/.local/share/moonarch/themes/current/ghostty.conf"' "$repo_root/home/.config/ghostty/config" || fail 'Ghostty does not import the current theme'
if grep -Eq '^[[:space:]]*config-file[[:space:]]*=' "$repo_root/home/.config/ghostty/config-clean"; then
    fail 'Ghostty clean profile must inherit the default theme without overriding config-file'
fi
grep -Fqx 'fragment="${HOME}/.local/share/moonarch/themes/current/rofi.rasi"' "$repo_root/home/.config/rofi/scripts/launch" || fail 'Rofi launcher does not select the current theme fragment'
grep -Fq "printf '@import \"%s\"\\n' \"\$fragment_abs\"" "$repo_root/home/.config/rofi/scripts/launch" || fail 'Rofi launcher does not compose the current theme fragment'
printf 'PASS: repository consumers bind to the current theme\n'

printf 'PASS: %d MoonArch selector scenarios\n' "$pass_count"
