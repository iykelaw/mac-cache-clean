# mac-cache-clean

Safe macOS cache cleanup for developers — as a **Cursor Agent Skill** and a
standalone shell script.

Use this instead of unsigned “disk cleaner” apps or remote `curl | bash`
installers. The script is short, local, and auditable.

## What it does

| Mode | Behavior |
|------|----------|
| *(default)* | **Scan only** — print sizes, no deletes |
| `--clean` | Move known regenerable caches to Trash, then prune Homebrew / pnpm / Docker build cache |
| `--clean --aggressive` | Also prune unused Docker volumes and delete unavailable iOS simulators |

Moved files land in `~/.Trash/cache-clean-<timestamp>/`. Empty Trash in Finder
to reclaim the space.

## What gets cleaned (`--clean`)

Regenerable caches only, for example:

- Browser caches (Chrome / Google, DuckDuckGo, Firefox, Safari cache dirs)
- Homebrew, pip, Yarn, Playwright, CocoaPods caches
- `~/.npm`, `~/.cache`, `~/.gradle/caches`
- Xcode DerivedData
- Cursor / VS Code **Cache**, **CachedData**, **logs**, **snapshots** (not settings)
- `/opt/homebrew/var/cache` and `/usr/local/var/cache` when present

Plus tool prunes when installed:

- `brew cleanup -s --prune=all`
- `pnpm store prune`
- `docker builder prune -af` and `docker image prune -af`

## What it never touches (default)

- Keychains, passwords, cookies
- Cursor / VS Code **User** folders and chat/state DBs
- Your project source trees
- Docker Desktop’s VM disk by path
- Active Docker volumes (unless you opt into `--aggressive`)

See [SECURITY.md](SECURITY.md) for the threat model.

## Requirements

- macOS (Darwin)
- Optional: Homebrew, pnpm, Docker Desktop, Xcode CLT (`xcrun simctl`)

## Install as a Cursor skill

Cursor loads personal skills from `~/.cursor/skills/<name>/`.

```bash
git clone https://github.com/iykelaw/mac-cache-clean.git \
  ~/.cursor/skills/mac-cache-clean
chmod +x ~/.cursor/skills/mac-cache-clean/scripts/clean-caches.sh
```

Or keep the clone elsewhere and symlink:

```bash
git clone https://github.com/iykelaw/mac-cache-clean.git ~/src/mac-cache-clean
ln -s ~/src/mac-cache-clean ~/.cursor/skills/mac-cache-clean
```

### Use in chat

Ask Cursor things like:

- “Clean my caches”
- “Free disk space on this Mac”
- “Scan regenerable developer caches”

The agent should load `SKILL.md` and run the bundled script.

### Team / project install

To share with one repo’s contributors:

```bash
git submodule add https://github.com/iykelaw/mac-cache-clean.git \
  .cursor/skills/mac-cache-clean
```

## CLI usage (no Cursor required)

```bash
cd mac-cache-clean
chmod +x scripts/clean-caches.sh

# 1. See what would free space
./scripts/clean-caches.sh

# 2. Clean safe caches
./scripts/clean-caches.sh --clean

# 3. Optional: unused Docker volumes + unavailable simulators
./scripts/clean-caches.sh --clean --aggressive
```

Optional shell alias:

```bash
alias cacheclean='$HOME/.cursor/skills/mac-cache-clean/scripts/clean-caches.sh --clean'
```

## Why not Clearaer / random installers?

Piping a remote script into `bash` and clearing Gatekeeper quarantine on an
**ad-hoc signed** Mac app removes the OS check that the binary came from an
identified developer. This repo keeps the same *job* (scan → clean regenerable
caches) as readable shell + Cursor instructions you can review before running.

## Layout

```
mac-cache-clean/
├── README.md                 # humans
├── SKILL.md                  # Cursor agent instructions
├── SECURITY.md
├── CONTRIBUTING.md
├── LICENSE
└── scripts/
    └── clean-caches.sh       # scan / clean implementation
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs that add only regenerable paths and
keep the skill small are welcome.

## License

[MIT](LICENSE)
