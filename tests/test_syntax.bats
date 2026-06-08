#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export REPO_ROOT
}

@test "nous_hermes_agent_install.sh passes bash syntax check" {
    run bash -n "$REPO_ROOT/nous_hermes_agent_install.sh"
    [ "$status" -eq 0 ]
}

@test "install.sh passes bash syntax check" {
    run bash -n "$REPO_ROOT/install.sh"
    [ "$status" -eq 0 ]
}

@test "agent_install.sh passes bash syntax check" {
    run bash -n "$REPO_ROOT/agent_install.sh"
    [ "$status" -eq 0 ]
}

@test "hermes_install.sh passes bash syntax check" {
    run bash -n "$REPO_ROOT/hermes_install.sh"
    [ "$status" -eq 0 ]
}

@test "nous_agent.sh passes bash syntax check" {
    run bash -n "$REPO_ROOT/nous_agent.sh"
    [ "$status" -eq 0 ]
}

@test "proot_install.sh passes bash syntax check" {
    run bash -n "$REPO_ROOT/proot_install.sh"
    [ "$status" -eq 0 ]
}

@test "all scripts declare a bash interpreter in the shebang" {
    local script
    for script in "$REPO_ROOT"/*.sh; do
        run bash -c "head -1 '$script' | grep -q 'bash'"
        [ "$status" -eq 0 ]
    done
}
