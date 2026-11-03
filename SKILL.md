---
name: mac-cache-clean
description: >-
  Safely free macOS disk space by scanning and cleaning regenerable caches
  (browser, Homebrew, npm/pnpm, Gradle, Cursor/VS Code caches, Docker build
  cache) without installing unsigned cleaners. Use when the user asks to clean
  caches, free disk space, reclaim storage, clear derived data, prune Docker
  build cache, or wants a Clearaer-style cleanup.
---

# macOS cache clean

## Goal

Free space the way a cache-cleaner app would, without downloading unsigned
software or bypassing Gatekeeper.

## Locate the script

This skill ships with `scripts/clean-caches.sh` next to this file.

1. Resolve the skill root (directory that contains this `SKILL.md`).
2. Prefer that copy of the script so installs from git, symlinks, or
   `~/.cursor/skills/` all work:
   ```bash
   bash "<skill-root>/scripts/clean-caches.sh"
   ```

## Workflow

1. Run **scan** mode first (no deletes):
   ```bash
   bash "<skill-root>/scripts/clean-caches.sh"
   ```
2. Summarize the largest safe targets and free disk on `/System/Volumes/Data`.
3. If the user wants cleanup (or already asked to clean), run:
   ```bash
   bash "<skill-root>/scripts/clean-caches.sh" --clean
   ```
   Needs full filesystem permissions outside the sandbox.
4. Report: free space before/after, what moved to Trash, and the Trash folder
   path. Remind them to empty Trash to reclaim the moved bytes.

## Safety rules (hard)

- Never delete Keychains, Cookies, passwords, or login items.
- Never delete Cursor/VS Code `User` folders (`…/Application Support/Cursor/User`,
  `…/Code/User`) or `state.vscdb`.
- Never `rm -rf` Docker’s VM disk or project Docker volumes by path.
- Prefer moving to `~/.Trash/cache-clean-<timestamp>/` over permanent delete.
- Do not install unsigned cleaners or run remote `curl | bash` installers.

## Optional (ask first)

Only with explicit user OK, then either re-run with `--clean --aggressive` or
run the specific command:

| Target | Command |
|--------|---------|
| Unused Docker volumes | `docker volume prune -f` (or script `--aggressive`) |
| Unavailable simulators | `xcrun simctl delete unavailable` |
| Whole pnpm store wipe | Ask; prefer `pnpm store prune` only |
| Ollama models | Delete `~/.ollama/models` only if they confirm |

## Reply shape

Keep it short: free space delta, top cleaned items, anything left large that
needs a separate decision.
