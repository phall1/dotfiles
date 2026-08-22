#!/usr/bin/env bash
# Focused smoke coverage for gha-local's actrc and checkout isolation.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
wrapper="$repo_root/dot_local/bin/executable_gha-local"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/gha-local-smoke.XXXXXXXX")"
test_root="$(cd "$test_root" && pwd -P)"
cleanup() {
    rm -rf -- "$test_root"
}
trap cleanup EXIT

fake_bin="$test_root/bin"
fake_home="$test_root/global-home"
fake_xdg="$test_root/global-xdg"
checkout="$test_root/checkout"
mkdir -p "$fake_bin" "$fake_home" "$fake_xdg/act" \
    "$checkout/.github/workflows"

git -C "$checkout" init -q
: > "$checkout/.github/workflows/ci.yml"

# These files would make a real act invocation unsafe or invalid if any of its
# three automatic actrc lookup locations leaked through the wrapper.
printf '%s\n' '--definitely-invalid-global-option' > "$fake_home/.actrc"
printf '%s\n' '--bind --directory /untrusted' > "$checkout/.actrc"
printf '%s\n' '--definitely-invalid-xdg-option' > "$fake_xdg/act/actrc"

cat > "$fake_bin/act" <<'FAKE_ACT'
#!/usr/bin/env bash
set -euo pipefail

for actrc in "$XDG_CONFIG_HOME/act/actrc" "$HOME/.actrc" "$PWD/.actrc"; do
    if [[ -e "$actrc" ]]; then
        printf 'fake act: automatically loaded actrc: %s\n' "$actrc" >&2
        exit 90
    fi
done

{
    printf 'pwd=%s\n' "$PWD"
    printf 'home=%s\n' "$HOME"
    printf 'xdg=%s\n' "$XDG_CONFIG_HOME"
    printf 'arg=%s\n' "$@"
} > "$GHA_LOCAL_TEST_CAPTURE"
FAKE_ACT
chmod +x "$fake_bin/act"

cat > "$fake_bin/docker" <<'FAKE_DOCKER'
#!/usr/bin/env bash
[[ "${1:-}" == "info" ]]
FAKE_DOCKER
chmod +x "$fake_bin/docker"

fail() {
    printf 'not ok: %s\n' "$*" >&2
    exit 1
}

assert_line() {
    local file="$1" expected="$2"
    grep -Fqx -- "$expected" "$file" \
        || fail "missing '$expected' in $file"
}

assert_no_line() {
    local file="$1" unexpected="$2"
    if grep -Fqx -- "$unexpected" "$file"; then
        fail "unexpected '$unexpected' in $file"
    fi
}

assert_common_defaults() {
    local capture="$1" invocation home xdg runtime
    invocation="$(sed -n 's/^pwd=//p' "$capture")"
    home="$(sed -n 's/^home=//p' "$capture")"
    xdg="$(sed -n 's/^xdg=//p' "$capture")"
    runtime="${invocation%/run}"

    [[ "$invocation" == "$runtime/run" ]] \
        || fail "act invocation directory was not private"
    [[ "$home" == "$runtime/home" ]] \
        || fail "act HOME was not isolated with its runtime"
    [[ "$xdg" == "$runtime/xdg" ]] \
        || fail "act XDG_CONFIG_HOME was not isolated with its runtime"
    [[ ! -e "$runtime" ]] \
        || fail "private act runtime was not removed"

    assert_line "$capture" "arg=--directory"
    assert_line "$capture" "arg=$checkout"
    assert_line "$capture" "arg=--env-file"
    assert_line "$capture" "arg=--input-file"
    assert_line "$capture" "arg=--secret-file"
    assert_line "$capture" "arg=--var-file"
    assert_line "$capture" "arg=/dev/null"
    assert_line "$capture" "arg=--artifact-server-addr"
    assert_line "$capture" "arg=127.0.0.1"
    assert_line "$capture" "arg=--artifact-server-path"
    assert_line "$capture" "arg="
    assert_line "$capture" "arg=--bind=false"
    assert_no_line "$capture" "pwd=$checkout"
    assert_no_line "$capture" "home=$fake_home"
    assert_no_line "$capture" "xdg=$fake_xdg"
}

run_wrapper() {
    local capture="$1"
    shift
    (
        cd "$checkout"
        PATH="$fake_bin:$PATH" \
            HOME="$fake_home" \
            XDG_CONFIG_HOME="$fake_xdg" \
            GHA_LOCAL_TEST_CAPTURE="$capture" \
            "$wrapper" "$@"
    )
}

list_capture="$test_root/list.capture"
run_wrapper "$list_capture" list -W .github/workflows/ci.yml --verbose
assert_common_defaults "$list_capture"
assert_line "$list_capture" "arg=--list"
assert_line "$list_capture" "arg=-W"
assert_line "$list_capture" "arg=$checkout/.github/workflows/ci.yml"
assert_line "$list_capture" "arg=--verbose"

check_capture="$test_root/check.capture"
run_wrapper "$check_capture" check --action-offline-mode
assert_common_defaults "$check_capture"
assert_line "$check_capture" "arg=--validate"
assert_line "$check_capture" "arg=--dryrun"
assert_line "$check_capture" "arg=--workflows"
assert_line "$check_capture" "arg=$checkout/.github/workflows"
assert_line "$check_capture" "arg=--action-offline-mode"

run_capture="$test_root/run.capture"
(
    export GHA_LOCAL_CONTAINER_ARCH=linux/test64
    run_wrapper "$run_capture" run test pull_request -- \
        --workflows=.github/workflows/ci.yml \
        --platform test-runner=test-image
)
assert_common_defaults "$run_capture"
assert_line "$run_capture" "arg=pull_request"
assert_line "$run_capture" "arg=-j"
assert_line "$run_capture" "arg=test"
assert_line "$run_capture" "arg=--container-architecture"
assert_line "$run_capture" "arg=linux/test64"
assert_line "$run_capture" "arg=--workflows=$checkout/.github/workflows/ci.yml"
assert_line "$run_capture" "arg=--platform"
assert_line "$run_capture" "arg=test-runner=test-image"

printf 'ok: gha-local isolates actrc files and preserves checkout arguments\n'
