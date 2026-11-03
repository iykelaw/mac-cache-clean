# Contributing

## Scope

Keep this skill small and boring:

- Prefer adding regenerable cache paths over broad `~/Library` sweeps
- Keep agent instructions in `SKILL.md` under ~100 lines when possible
- Put human-facing docs in `README.md` / `SECURITY.md`

## Adding a safe path

1. Confirm the folder rebuilds automatically (package manager cache, IDE
   browser cache, build artifacts).
2. Confirm it does **not** hold login state, keys, or irreplaceable project
   data.
3. Add it to `SAFE_PATHS` in `scripts/clean-caches.sh`.
4. Mention it in the README “What gets cleaned” table.
5. Run a scan on your machine before opening a PR:
   ```bash
   ./scripts/clean-caches.sh
   ```

## Aggressive / optional targets

Anything that can drop local databases, simulator devices, or Docker volumes
belongs behind an explicit ask in `SKILL.md` and/or `--aggressive` — not in
the default `--clean` list.

## Pull requests

- One focused change per PR
- No binary blobs or signed apps
- Update docs when behavior changes
