# Security

## What this tool is for

`mac-cache-clean` is a small, auditable Bash script plus a Cursor Agent Skill.
It frees macOS disk space by removing **regenerable developer/browser caches**.
It is meant as a safer alternative to unsigned cache-cleaner apps and
`curl … | bash` installers.

## Guarantees (and non-guarantees)

- The script is short and readable. Read it before running `--clean`.
- Default `--clean` **moves** known-safe folders into `~/.Trash/…` instead of
  permanently deleting them.
- It does **not** claim to remove malware, and it does **not** need root.
- It does **not** network-exfiltrate files. Optional Docker/Homebrew/pnpm
  commands only talk to local tooling / registries those tools already use.

## Never touched by default

- Keychains, passwords, cookies, browser profiles
- Cursor / VS Code `User` settings and chat databases (`state.vscdb`)
- Project source trees
- Docker Desktop’s VM disk path (`…/com.docker.docker/Data/vms`)
- Named Docker volumes for apps (unless you pass `--aggressive`, which only
  runs `docker volume prune` for **unused** volumes)

## Reporting issues

Open a GitHub issue describing:

1. macOS version
2. Exact command you ran
3. Unexpected path that was moved or pruned

Do not attach secrets, keychain dumps, or `.env` files.
