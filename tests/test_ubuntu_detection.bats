#!/usr/bin/env bats

# Tests the ubuntu-already-installed detection logic.
# Also documents a known grep-pipe bug in nous_agent.sh.
#
# Assumption: proot-distro list outputs status on the same line as the distro name,
# e.g. "* ubuntu (Ubuntu)  Installed: yes". The grep pipeline in
# nous_hermes_agent_install.sh relies on this single-line format.

@test "correct pattern: detects ubuntu when installed" {
    run bash -c '
        list_output="* ubuntu (Ubuntu)  Installed: yes"
        if echo "$list_output" | grep -i "ubuntu" | grep -q "Installed: yes"; then
            echo "detected"
        else
            echo "not_detected"
        fi
    '
    [ "$status" -eq 0 ]
    [ "$output" = "detected" ]
}

@test "correct pattern: skips when ubuntu is not installed" {
    run bash -c '
        list_output="* ubuntu (Ubuntu)  Installed: no"
        if echo "$list_output" | grep -i "ubuntu" | grep -q "Installed: yes"; then
            echo "detected"
        else
            echo "not_detected"
        fi
    '
    [ "$status" -eq 0 ]
    [ "$output" = "not_detected" ]
}

@test "correct pattern: does not false-positive when a different distro is installed" {
    run bash -c '
        list_output="* alpine (Alpine Linux)  Installed: yes
* ubuntu (Ubuntu)  Installed: no"
        if echo "$list_output" | grep -i "ubuntu" | grep -q "Installed: yes"; then
            echo "detected"
        else
            echo "not_detected"
        fi
    '
    [ "$status" -eq 0 ]
    [ "$output" = "not_detected" ]
}

# KNOWN BUG in nous_agent.sh line 29:
#   proot-distro list | grep -q "Installed: yes" | grep "ubuntu"
#
# grep -q suppresses stdout, so the second grep always receives empty input,
# always exits 1, and the surrounding `if !` makes the whole condition always
# true — proot-distro install ubuntu runs on every execution, even if ubuntu
# is already installed. The fix is the pattern tested above (grep ubuntu first,
# then grep -q for the status).
@test "KNOWN BUG - nous_agent.sh grep-pipe pattern always treats ubuntu as uninstalled" {
    run bash -c '
        list_output="* ubuntu (Ubuntu)
  Installed: yes"
        if echo "$list_output" | grep -q "Installed: yes" | grep -q "ubuntu"; then
            echo "detected"
        else
            echo "not_detected"
        fi
    '
    [ "$status" -eq 0 ]
    # Bug: reports not_detected even when ubuntu IS installed
    [ "$output" = "not_detected" ]
}
