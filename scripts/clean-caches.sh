#!/usr/bin/env bash
# Safe macOS regenerable-cache cleaner.
# Prefer this over unsigned "cache cleaner" apps or curl|bash installers.
#
# Usage:
#   ./scripts/clean-caches.sh                 # scan sizes only
#   ./scripts/clean-caches.sh --clean         # move safe caches to Trash + prune tools
#   ./scripts/clean-caches.sh --clean --aggressive
#       Also prune unused Docker volumes and delete unavailable iOS simulators.
#
# Exit codes: 0 ok, 1 usage/OS error
set -euo pipefail

MODE="scan"
AGGRESSIVE=0
for arg in "$@"; do
  case "$arg" in
    --clean) MODE="clean" ;;
    --aggressive) AGGRESSIVE=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown flag: $arg (try --help)" >&2
      exit 1
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This cleaner is for macOS only." >&2
  exit 1
fi

HOME_DIR="${HOME}"
STAMP="$(date +%Y%m%d-%H%M%S)"
TRASH_DIR="${HOME_DIR}/.Trash/cache-clean-${STAMP}"

# Paths that rebuild themselves. Never include Keychains, Cookies, or
# Cursor/Code User settings folders.
SAFE_PATHS=(
  "${HOME_DIR}/Library/Caches/Google"
  "${HOME_DIR}/Library/Caches/com.google.Chrome"
  "${HOME_DIR}/Library/Caches/com.duckduckgo.macos.browser"
  "${HOME_DIR}/Library/Caches/Firefox"
  "${HOME_DIR}/Library/Caches/Mozilla"
  "${HOME_DIR}/Library/Caches/com.apple.Safari"
  "${HOME_DIR}/Library/Caches/GeoServices"
  "${HOME_DIR}/Library/Caches/com.apple.helpd"
  "${HOME_DIR}/Library/Caches/Homebrew"
  "${HOME_DIR}/Library/Caches/pip"
  "${HOME_DIR}/Library/Caches/Yarn"
  "${HOME_DIR}/Library/Caches/ms-playwright"
  "${HOME_DIR}/Library/Caches/CocoaPods"
  "${HOME_DIR}/.gradle/caches"
  "${HOME_DIR}/.npm"
  "${HOME_DIR}/.cache"
  "${HOME_DIR}/Library/Developer/Xcode/DerivedData"
  "${HOME_DIR}/Library/Application Support/Cursor/Cache"
  "${HOME_DIR}/Library/Application Support/Cursor/CachedData"
  "${HOME_DIR}/Library/Application Support/Cursor/CachedExtensionVSIXs"
  "${HOME_DIR}/Library/Application Support/Cursor/logs"
  "${HOME_DIR}/Library/Application Support/Cursor/snapshots"
  "${HOME_DIR}/Library/Application Support/Code/Cache"
  "${HOME_DIR}/Library/Application Support/Code/CachedData"
  "${HOME_DIR}/Library/Application Support/Code/logs"
  "/opt/homebrew/var/cache"
  "/usr/local/var/cache"
)

human_size() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "—"
    return
  fi
  du -sh "$path" 2>/dev/null | awk '{print $1}' || echo "?"
}

print_disk() {
  df -h /System/Volumes/Data 2>/dev/null | awk 'NR==1 || /Data/' \
    || df -h /
}

echo "=== Disk ==="
print_disk
echo
echo "=== Safe regenerable caches ==="
total_found=0
for path in "${SAFE_PATHS[@]}"; do
  if [[ -e "$path" ]]; then
    sz="$(human_size "$path")"
    printf "%8s  %s\n" "$sz" "$path"
    total_found=$((total_found + 1))
  fi
done
if [[ "$total_found" -eq 0 ]]; then
  echo "(none present)"
fi

echo
echo "=== Optional / ask before deleting ==="
printf "%8s  %s\n" "$(human_size "${HOME_DIR}/Library/pnpm")" "pnpm store (${HOME_DIR}/Library/pnpm) — use: pnpm store prune"
printf "%8s  %s\n" "$(human_size "${HOME_DIR}/Library/Developer/CoreSimulator/Devices")" "iOS Simulator devices — use: xcrun simctl delete unavailable"
printf "%8s  %s\n" "$(human_size "${HOME_DIR}/Library/Containers/com.docker.docker/Data/vms")" "Docker Desktop VM disk — prune with docker, do not rm"
printf "%8s  %s\n" "$(human_size "${HOME_DIR}/.ollama/models")" "Ollama models — only if you can redownload"

if command -v docker >/dev/null 2>&1; then
  echo
  echo "=== Docker (docker system df) ==="
  docker system df 2>/dev/null || echo "Docker not reachable"
fi

if [[ "$MODE" != "clean" ]]; then
  echo
  echo "Scan only. Re-run with --clean to move safe caches to Trash and prune tools."
  exit 0
fi

echo
echo "=== Cleaning safe caches → ${TRASH_DIR} ==="
mkdir -p "${TRASH_DIR}"
moved=0
for path in "${SAFE_PATHS[@]}"; do
  if [[ -e "$path" ]]; then
    base="$(basename "$path")"
    # Avoid collisions when multiple paths share a basename.
    dest="${TRASH_DIR}/${moved}-${base}"
    sz="$(human_size "$path")"
    if mv "$path" "$dest" 2>/dev/null; then
      printf "TRASH %8s  %s\n" "$sz" "$path"
      moved=$((moved + 1))
    else
      printf "FAIL  %8s  %s\n" "$sz" "$path"
    fi
  fi
done

if command -v brew >/dev/null 2>&1; then
  echo
  echo "=== brew cleanup ==="
  brew cleanup -s --prune=all || true
fi

if command -v pnpm >/dev/null 2>&1; then
  echo
  echo "=== pnpm store prune ==="
  pnpm store prune || true
fi

if command -v docker >/dev/null 2>&1; then
  echo
  echo "=== docker builder + unused images ==="
  docker builder prune -af || true
  docker image prune -af || true
  if [[ "$AGGRESSIVE" -eq 1 ]]; then
    echo "=== docker unused volumes (--aggressive) ==="
    docker volume prune -f || true
  fi
fi

if [[ "$AGGRESSIVE" -eq 1 ]] && command -v xcrun >/dev/null 2>&1; then
  echo
  echo "=== xcrun simctl delete unavailable (--aggressive) ==="
  xcrun simctl delete unavailable || true
fi

echo
echo "=== Disk after ==="
print_disk
if [[ -d "${TRASH_DIR}" ]]; then
  echo
  printf "Trashed bundle: %s (%s)\n" "$(human_size "${TRASH_DIR}")" "${TRASH_DIR}"
  echo "Empty Trash in Finder to reclaim that space."
fi
