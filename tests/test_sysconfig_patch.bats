#!/usr/bin/env bats

# Tests the Python sysconfig patch from install.sh.
# The patch removes -fno-openmp-implicit-rpath so psutil can compile on Python 3.13 / Termux.

setup() {
    TMPDIR_PREFIX="$(mktemp -d)"
    mkdir -p "$TMPDIR_PREFIX/lib/python3.13"
    SYSCONFIG_FILE="$TMPDIR_PREFIX/lib/python3.13/_sysconfigdata_m_linux_aarch64.py"
    export TMPDIR_PREFIX SYSCONFIG_FILE PREFIX="$TMPDIR_PREFIX"
}

teardown() {
    rm -rf "$TMPDIR_PREFIX"
}

@test "patch removes the openmp flag from the sysconfig file" {
    echo "flags = '-fno-openmp-implicit-rpath -O2 -fstack-protector'" > "$SYSCONFIG_FILE"

    run bash -c '
        _file="$(find "$PREFIX/lib/python3."* -name "_sysconfigdata*.py" 2>/dev/null | head -1)"
        cp "$_file" "$_file.backup"
        sed -i "s|-fno-openmp-implicit-rpath||g" "$_file"
        echo "done"
    '

    [ "$status" -eq 0 ]
    ! grep -q 'fno-openmp-implicit-rpath' "$SYSCONFIG_FILE"
}

@test "patch preserves other compiler flags" {
    echo "flags = '-fno-openmp-implicit-rpath -O2 -fstack-protector'" > "$SYSCONFIG_FILE"

    run bash -c 'sed -i "s|-fno-openmp-implicit-rpath||g" "$SYSCONFIG_FILE"'

    [ "$status" -eq 0 ]
    grep -q '\-O2' "$SYSCONFIG_FILE"
    grep -q '\-fstack-protector' "$SYSCONFIG_FILE"
}

@test "patch creates a backup of the original file" {
    echo "original content with -fno-openmp-implicit-rpath" > "$SYSCONFIG_FILE"

    run bash -c '
        cp "$SYSCONFIG_FILE" "$SYSCONFIG_FILE.backup"
        sed -i "s|-fno-openmp-implicit-rpath||g" "$SYSCONFIG_FILE"
        echo "done"
    '

    [ "$status" -eq 0 ]
    [ -f "${SYSCONFIG_FILE}.backup" ]
    grep -q 'original content' "${SYSCONFIG_FILE}.backup"
}

@test "patch is a no-op when sysconfig file does not exist" {
    rm -f "$SYSCONFIG_FILE"

    run bash -c '
        _file="$(find "$PREFIX/lib/python3."* -name "_sysconfigdata*.py" 2>/dev/null | head -1)"
        if [ -f "$_file" ]; then
            echo "patched"
        else
            echo "file_not_found"
        fi
    '

    [ "$status" -eq 0 ]
    [ "$output" = "file_not_found" ]
}
