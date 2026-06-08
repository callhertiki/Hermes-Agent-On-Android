#!/usr/bin/env bats

# Tests error handling patterns across the installer scripts.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export REPO_ROOT
}

@test "nous_hermes_agent_install.sh uses strict error handling (set -euo pipefail)" {
    run grep -q "set -euo pipefail" "$REPO_ROOT/nous_hermes_agent_install.sh"
    [ "$status" -eq 0 ]
}

@test "install.sh only uses set -e, leaving pipeline errors undetected" {
    # Documents that install.sh has incomplete error handling — pipeline failures
    # (e.g. a failing git clone piped through tee) would be silently swallowed.
    run grep "^set " "$REPO_ROOT/install.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == "set -e" ]]
}

# Demonstrates why the missing pipefail matters.
@test "set -e alone does not abort on a pipeline failure" {
    run bash -c "
        set -e
        false | true
        echo 'reached'
    "
    [ "$status" -eq 0 ]
    [ "$output" = "reached" ]
}

@test "set -euo pipefail aborts on a pipeline failure" {
    run bash -c "
        set -euo pipefail
        false | true
        echo 'should not reach here'
    "
    [ "$status" -ne 0 ]
}

@test "getprop fallback returns a numeric SDK version when not on Android" {
    # install.sh line 57: uses 2>/dev/null || echo 24 — should work on any host
    run bash -c '
        level="$(getprop ro.build.version.sdk 2>/dev/null || echo 24)"
        echo "$level"
    '
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+$ ]]
}

@test "PATH dedup check prevents double-adding .local/bin to .bashrc" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    local bashrc="$tmpdir/.bashrc"
    touch "$bashrc"

    run bash -c "
        HOME='$tmpdir'
        bashrc='$bashrc'

        # First install run
        if ! echo \"\$PATH\" | grep -q \"\$HOME/.local/bin\"; then
            echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \"\$bashrc\"
        fi
        export PATH=\"\$HOME/.local/bin:\$PATH\"

        # Second install run (re-running the installer) should not add a duplicate
        if ! echo \"\$PATH\" | grep -q \"\$HOME/.local/bin\"; then
            echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \"\$bashrc\"
        fi

        grep -c 'local/bin' \"\$bashrc\"
    "

    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
    rm -rf "$tmpdir"
}
