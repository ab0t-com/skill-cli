#!/usr/bin/env sh
# =============================================================================
# skills installer (public GitHub release)
# =============================================================================
#
# Downloads the `skills` binary from this GitHub repo's raw content and
# installs it, verifying the published sha256 before touching anything.
#
# What it does:
#   1. Detects host OS + arch. (Only linux-amd64 is published today; it fails
#      clearly on anything else rather than installing the wrong thing.)
#   2. Downloads release/checksums.txt, then release/skills, over HTTPS.
#   3. Verifies the binary against the published sha256 — mandatory.
#   4. Atomically installs to $PREFIX/bin/skills (default /usr/local/bin),
#      keeping the prior binary as `.previous`.
#   5. Confirms with `skills --version` and points you at `skills setup`.
#
# Properties (compliance):
#   - POSIX sh; runs under /bin/sh on Linux/macOS/busybox.
#   - HTTPS only — TLS verification ALWAYS on (`-k`/`--insecure` never used).
#   - sha256 verification is mandatory; refuses to install on mismatch or a
#     missing checksums.txt.
#   - No destructive operations: never `rm -rf`, never deletes user data,
#     only writes the install dir + a temp dir it creates and cleans up.
#   - Atomic install via `install`/`mv` of a fully-verified tempfile.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ab0t-com/skill-cli/main/install.sh | sh
#   PREFIX=$HOME/.local sh install.sh        # user-local install (no sudo)
# =============================================================================
set -eu

REPO_RAW="${SKILL_REPO_RAW:-https://raw.githubusercontent.com/ab0t-com/skill-cli/main}"
PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="$PREFIX/bin"
NAME="skills"

say()  { printf '%s\n' "$*"; }
die()  { printf 'install.sh: error: %s\n' "$*" >&2; exit 1; }

# --- 1. platform gate --------------------------------------------------------
os="$(uname -s 2>/dev/null || echo unknown)"
arch="$(uname -m 2>/dev/null || echo unknown)"
case "$os/$arch" in
  Linux/x86_64) ;;
  *) die "only linux-amd64 binaries are published today (got $os/$arch). Build from source instead." ;;
esac

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required"

# --- 2. fetch into a private temp dir ---------------------------------------
tmp="$(mktemp -d "${TMPDIR:-/tmp}/skills-install.XXXXXX")" || die "mktemp failed"
trap 'rm -rf "$tmp"' EXIT INT TERM

say "fetching checksums..."
curl -fsSL "$REPO_RAW/release/checksums.txt" -o "$tmp/checksums.txt" \
  || die "could not download checksums.txt — refusing to install unverified"

say "fetching $NAME binary..."
curl -fsSL "$REPO_RAW/release/$NAME" -o "$tmp/$NAME" \
  || die "could not download the binary"

# --- 3. mandatory sha256 verification ----------------------------------------
( cd "$tmp" && grep " $NAME\$" checksums.txt | sha256sum -c - >/dev/null 2>&1 ) \
  || die "sha256 MISMATCH — the downloaded binary does not match the published checksum. Aborting."
say "sha256 verified."

# --- 4. atomic install --------------------------------------------------------
chmod 0755 "$tmp/$NAME"
mkdir -p "$BIN_DIR" 2>/dev/null || true
[ -w "$BIN_DIR" ] || die "$BIN_DIR is not writable (re-run with sudo, or PREFIX=\$HOME/.local)"

if [ -e "$BIN_DIR/$NAME" ]; then
  mv "$BIN_DIR/$NAME" "$BIN_DIR/$NAME.previous"
  say "kept prior binary as $NAME.previous"
fi
mv "$tmp/$NAME" "$BIN_DIR/$NAME"

# --- 5. confirm ----------------------------------------------------------------
say "installed: $("$BIN_DIR/$NAME" --version)"
say ""
say "next steps:"
say "  $NAME setup        # first-run: seeds a starter skill set + shim + PATH + doctor"
say "  $NAME help         # full command reference"
say "  see llms.txt in this repo if you are an AI agent bootstrapping yourself"
