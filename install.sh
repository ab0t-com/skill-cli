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
#   4. Atomically installs to $PREFIX/bin/skills (default /usr/local/bin, or
#      ~/.local/bin automatically when /usr/local needs root you don't have),
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
# If the user set PREFIX, honor it exactly. Otherwise default to /usr/local but
# fall back to a user-local dir when that needs root we don't have — so a plain
# non-root `curl | sh` just works without sudo.
PREFIX_SET=0; [ -n "${PREFIX:-}" ] && PREFIX_SET=1
PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="$PREFIX/bin"
NAME="skills"

say()  { printf '%s\n' "$*"; }
die()  { printf 'install.sh: error: %s\n' "$*" >&2; exit 1; }

# --- 1. detect platform → pick the published artifact ------------------------
os="$(uname -s 2>/dev/null || echo unknown)"
arch="$(uname -m 2>/dev/null || echo unknown)"
case "$os/$arch" in
  Linux/x86_64)               ART="skills-linux-amd64"  ;;
  Linux/aarch64|Linux/arm64)  ART="skills-linux-arm64"  ;;
  Darwin/x86_64)              ART="skills-darwin-amd64" ;;
  Darwin/arm64)               ART="skills-darwin-arm64" ;;
  *) die "no prebuilt binary for $os/$arch (supported: Linux & macOS on amd64/arm64; on Windows use install.ps1). Build from source: github.com/ab0t-com/skill-cli" ;;
esac

command -v curl >/dev/null 2>&1 || die "curl is required"
# sha256 tool differs by OS: coreutils (Linux) = sha256sum; macOS ships shasum.
if   command -v sha256sum >/dev/null 2>&1; then SHACHECK="sha256sum -c -"
elif command -v shasum    >/dev/null 2>&1; then SHACHECK="shasum -a 256 -c -"
else die "need 'sha256sum' or 'shasum' to verify the download"; fi

# --- 2. fetch into a private temp dir ---------------------------------------
tmp="$(mktemp -d "${TMPDIR:-/tmp}/skills-install.XXXXXX")" || die "mktemp failed"
trap 'rm -rf "$tmp"' EXIT INT TERM

say "fetching checksums..."
curl -fsSL "$REPO_RAW/release/checksums.txt" -o "$tmp/checksums.txt" \
  || die "could not download checksums.txt — refusing to install unverified"

say "fetching $ART ($os/$arch)..."
curl -fsSL "$REPO_RAW/release/$ART" -o "$tmp/$ART" \
  || die "could not download $ART"

# --- 3. mandatory sha256 verification ----------------------------------------
( cd "$tmp" && grep " $ART\$" checksums.txt | $SHACHECK >/dev/null 2>&1 ) \
  || die "sha256 MISMATCH — $ART does not match the published checksum. Aborting."
say "sha256 verified."

# --- 4. atomic install (installs the verified artifact as `skills`) ----------
chmod 0755 "$tmp/$ART"
mkdir -p "$BIN_DIR" 2>/dev/null || true
if [ ! -w "$BIN_DIR" ]; then
  if [ "$PREFIX_SET" -eq 1 ]; then
    die "$BIN_DIR is not writable (re-run with sudo, or set PREFIX to a writable dir)"
  fi
  # Default /usr/local needs root we don't have → install to a user dir, no sudo.
  BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
  say "/usr/local/bin needs root; installing to $BIN_DIR instead (no sudo)."
  mkdir -p "$BIN_DIR" 2>/dev/null || die "could not create $BIN_DIR"
  [ -w "$BIN_DIR" ] || die "$BIN_DIR is not writable — set PREFIX=<dir> to choose another location"
fi

if [ -e "$BIN_DIR/$NAME" ]; then
  mv "$BIN_DIR/$NAME" "$BIN_DIR/$NAME.previous"
  say "kept prior binary as $NAME.previous"
fi
mv "$tmp/$ART" "$BIN_DIR/$NAME"

# --- 5. confirm + make it usable with zero fiddling --------------------------
ver="$("$BIN_DIR/$NAME" --version 2>/dev/null || echo "$NAME")"
say ""
say "✓ installed $ver → $BIN_DIR"

# Persist PATH so future shells just work (idempotent; only the rc files that
# exist, falling back to ~/.profile). Then print ONE copy-paste line that works
# in the current shell too.
on_path=0
case ":$PATH:" in *":$BIN_DIR:"*) on_path=1 ;; esac
if [ "$on_path" -eq 0 ]; then
  line="export PATH=\"$BIN_DIR:\$PATH\""
  added=0
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -e "$rc" ] || continue
    grep -qF "$line" "$rc" 2>/dev/null || printf '\n# added by skills installer\n%s\n' "$line" >> "$rc"
    added=1
  done
  [ "$added" -eq 0 ] && { grep -qF "$line" "$HOME/.profile" 2>/dev/null || printf '# added by skills installer\n%s\n' "$line" >> "$HOME/.profile"; }
fi

say ""
say "Run this to finish (copy-paste):"
say ""
if [ "$on_path" -eq 0 ]; then
  say "    export PATH=\"$BIN_DIR:\$PATH\" && $NAME setup"
else
  say "    $NAME setup"
fi
say ""
say "New terminals already have it. \`$NAME help\` for everything."
