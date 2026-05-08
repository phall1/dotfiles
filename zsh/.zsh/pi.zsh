# Pi agent — nix devshell compatibility
#
# Pi's embedded JS runtime breaks inside nix devshells because nix sets dozens
# of C/C++ compilation env vars (CC, CXX, DEVELOPER_DIR, NIX_CFLAGS_COMPILE,
# etc.) that interfere with package installation and extension compilation.
# This wrapper strips those vars so pi starts cleanly regardless of shell env.

pi() {
  if [[ -z "$IN_NIX_SHELL" ]]; then
    command pi "$@"
    return
  fi

  # Build a clean PATH: user tools first, then homebrew/system, then whatever
  # nix left behind (so pi's own shell commands like git still work).
  local clean_path="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.npm-global/bin:$HOME/.cargo/bin"
  clean_path="$clean_path:/opt/homebrew/bin:/opt/homebrew/sbin"
  clean_path="$clean_path:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  # Append remaining PATH entries (includes nix store paths for tools pi shells out to)
  clean_path="$clean_path:$PATH"

  (
    # Strip nix build/compilation variables that break pi's startup
    unset CC CXX AR AS LD NM RANLIB STRIP OBJCOPY OBJDUMP SIZE
    unset CONFIG_SHELL DEVELOPER_DIR DETERMINISTIC_BUILD
    unset MACOSX_DEPLOYMENT_TARGET NIX_APPLE_SDK_VERSION
    unset NIX_BINTOOLS NIX_BINTOOLS_WRAPPER_TARGET_HOST_arm64_apple_darwin
    unset NIX_CC NIX_CC_WRAPPER_TARGET_HOST_arm64_apple_darwin
    unset NIX_CFLAGS_COMPILE NIX_LDFLAGS NIX_BUILD_CORES
    unset LIBCLANG_PATH CMAKE_INCLUDE_PATH CMAKE_LIBRARY_PATH
    unset NIXPKGS_CMAKE_PREFIX_PATH HOST_PATH
    export PATH="$clean_path"
    command pi "$@"
  )
}
