#!/usr/bin/env bash
# Mock-only tests for RiceInstaller's package planner. No system packages are
# installed, upgraded, removed, or queried outside the mocked package tools.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

source "$SCRIPT_DIR/lib/packages.sh"

RI_PACKAGE_REPORT="$TEST_DIR/missing_apps.txt"
ACTION_LOG="$TEST_DIR/actions.log"
REVERSE_INFO=""
: >"$ACTION_LOG"

info() { :; }
ok() { :; }
warn() { printf 'WARN %s\n' "$*" >&2; }
err() { printf 'ERR %s\n' "$*" >&2; }

pacman() {
    case "$1" in
        -T)
            case "$2" in
                already-provided) return 0 ;;
                *) return 127 ;;
            esac
            ;;
        -Qq)
            case "$2" in
                old-lib|old-app|old-custom) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        -Qi)
            printf '%s\n' "$REVERSE_INFO"
            return 0
            ;;
        *)
            printf 'unexpected pacman call: %s\n' "$*" >&2
            return 99
            ;;
    esac
}

paru() {
    if [[ "$1" == "-Si" ]]; then
        shift
        local package
        local status=0
        for package in "$@"; do
            case "$package" in
                official-new)
                    cat <<'META'
Repository      : extra
Name            : official-new
Conflicts With  : old-lib
Replaces        : old-lib
Provides        : old-lib

META
                    ;;
                aur-new)
                    cat <<'META'
Repository      : aur
Name            : aur-new
Conflicts With  : old-app
Replaces        : None
Provides        : old-app

META
                    ;;
                custom-new)
                    cat <<'META'
Repository      : cachyos
Name            : custom-new
Conflicts With  : old-custom
Replaces        : None
Provides        : old-custom

META
                    ;;
                safe-custom)
                    cat <<'META'
Repository      : cachyos
Name            : safe-custom
Conflicts With  : None
Replaces        : None
Provides        : None

META
                    ;;
                sdl2-compat)
                    cat <<'META'
Repository      : extra
Name            : sdl2-compat
Conflicts With  : sdl2
Replaces        : sdl2
Provides        : sdl2

META
                    ;;
                sdl2)
                    cat <<'META'
Repository      : aur
Name            : sdl2
Conflicts With  : sdl2-compat
Replaces        : None
Provides        : None

META
                    ;;
                reverse-new)
                    cat <<'META'
Repository      : aur
Name            : reverse-new
Conflicts With  : None
Replaces        : None
Provides        : None

META
                    ;;
                safe-new)
                    cat <<'META'
Repository      : extra
Name            : safe-new
Conflicts With  : None
Replaces        : None
Provides        : None

META
                    ;;
                unknown-package)
                    status=1
                    ;;
                *)
                    printf 'unexpected metadata target: %s\n' "$package" >&2
                    status=1
                    ;;
            esac
        done
        return "$status"
    fi

    printf 'paru %s\n' "$*" >>"$ACTION_LOG"
}

# pactrans is intentionally a shell function: the helper detects it, while
# the sudo mock below records the exact command without executing it.
pactrans() { :; }
sudo() { printf 'sudo %s\n' "$*" >>"$ACTION_LOG"; }

assert_contains() {
    grep -Fq -- "$1" "$2" || {
        printf 'FAIL: expected to find <%s> in %s\n' "$1" "$2" >&2
        exit 1
    }
}
assert_not_contains() {
    if grep -Fq -- "$1" "$2"; then
        printf 'FAIL: did not expect to find <%s> in %s\n' "$1" "$2" >&2
        exit 1
    fi
}

ri_package_install_targets "provider" required already-provided
[[ ! -s "$ACTION_LOG" ]]

ri_package_install_targets "official replacement" required official-new
assert_contains 'sudo pactrans --install --resolve-conflicts=provided --resolve-replacements=all official-new' "$ACTION_LOG"

: >"$ACTION_LOG"
ri_package_install_targets "AUR conflict" optional aur-new
ri_package_install_targets "custom conflict" optional custom-new
assert_not_contains 'paru -S' "$ACTION_LOG"
assert_not_contains 'pacman -S' "$ACTION_LOG"
assert_contains 'aur-new' "$RI_PACKAGE_REPORT"
assert_contains 'custom-new' "$RI_PACKAGE_REPORT"

: >"$ACTION_LOG"
ri_package_install_targets "custom safe" optional safe-custom
assert_contains 'sudo pacman -S --needed safe-custom' "$ACTION_LOG"
assert_not_contains 'sudo pactrans' "$ACTION_LOG"

: >"$ACTION_LOG"
ri_package_install_targets "pairwise replacement" optional sdl2-compat sdl2
assert_contains 'sudo pactrans --install --resolve-conflicts=provided --resolve-replacements=all sdl2-compat' "$ACTION_LOG"
assert_not_contains 'paru -S' "$ACTION_LOG"

: >"$ACTION_LOG"
REVERSE_INFO=$'Name            : old-reverse\nConflicts With  : reverse-new'
ri_package_install_targets "reverse conflict" optional reverse-new
assert_not_contains 'paru -S' "$ACTION_LOG"
assert_contains 'reverse-new' "$RI_PACKAGE_REPORT"

: >"$ACTION_LOG"
if ri_package_install_targets "unknown required" required unknown-package; then
    printf 'FAIL: unknown required package unexpectedly succeeded\n' >&2
    exit 1
fi
if ! ri_package_install_targets "unknown optional" optional unknown-package; then
    printf 'FAIL: unknown optional package should be skipped\n' >&2
    exit 1
fi
assert_not_contains 'sudo pactrans' "$ACTION_LOG"
assert_not_contains 'paru -S' "$ACTION_LOG"
assert_contains 'unknown-package' "$RI_PACKAGE_REPORT"

printf 'PASS: package planner mock tests\n'
