REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
MOCKS_DIR="$REPO_ROOT/tests/mocks"

setup_mocks() {
    chmod +x "$MOCKS_DIR"/* 2>/dev/null || true
    export PATH="$MOCKS_DIR:$PATH"
    export DEBIAN_FRONTEND=noninteractive
    export TZ=UTC
}

make_temp_dir() {
    mktemp -d
}
