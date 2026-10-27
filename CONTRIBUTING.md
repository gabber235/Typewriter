# Contributing

This document outlines the process for setting up the local development environment for this project.

## Local Development Setup

[devenv](https://devenv.sh) provides every tool (`devenv.nix`). Run commands inside `devenv shell`, or prefix them with `devenv shell --`. `cargo xtask` is the command surface: `cargo xtask --help` lists it, and `cargo xtask doctor` says what is wrong with a setup and how to fix it.

### Secrets

[`secretspec.toml`](secretspec.toml) declares every secret by name, grouped in profiles: `default` (local tools), `deploy`, `ci`, `bot`, `release` and `marketplace`. Values never live in the repository.

| Who | Where values come from |
|---|---|
| Maintainers | The `Typewriter` 1Password vault, through the desktop app's CLI integration or `OP_SERVICE_ACCOUNT_TOKEN` |
| Contributors without vault access | `.env` in the repository root: copy [`.env.example`](.env.example) and uncomment the keys you need |
| CI | The `OP_SERVICE_ACCOUNT_TOKEN` repository secret, in the jobs that need secrets only |

- `cargo xtask secrets check` shows which profiles resolve and what each one misses, never a value.
- xtask resolves the secrets its commands need itself (`deploy`, `cluster ci`, `e2e full`).
- Other tools start through `secretspec run`: `secretspec run -- pi` (Fibery, Greptime), `secretspec run --profile bot -- cargo run` in `discord_bot/`, `secretspec run --profile marketplace -- npm run dev` in `marketplace/website/`.
- Without 1Password, set `SECRETSPEC_PROVIDER=local` to read `.env` only and skip the vault's warning.
- A maintainer adds or changes a value with `secretspec set <KEY> --profile <profile>`; the vault item is `secretspec/typewriter/<profile>/<KEY>`.
- When an AI agent runs SecretSpec, it must give a reason: `--reason "<why>"` or `SECRETSPEC_REASON`.

## Commit Message Convention

This repository enforces Conventional Commits in local hooks and in GitHub Actions.

Use this format:

```text
type(scope): subject
```

Valid commit types:

`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

Scopes are defined in [`commit-scopes.json`](commit-scopes.json). When adding a new accepted scope, update that file in the same pull request.

`commit-scopes.json` is the complete list; the hook prints it when a scope is refused.

Multiple scopes are supported with commas.

```text
feat(backend/access/auth-callout,backend/tests): add auth endpoint coverage
```

Scope requirement policy:

- Scope is required for `feat`, `fix`, `refactor`, `perf`
- Scope is optional for `docs`, `style`, `test`, `build`, `ci`, `chore`, `revert`

Examples:

- `feat(panel): add route search`
- `test(backend/tests): add permission integration test`
- `fix(services/runtime/realm): handle empty title`
- `docs: update setup steps`

Entering `devenv shell` installs the `commit-msg` and `pre-commit` hooks; both run `cargo xtask hook`. Check a range of commits the way CI does with:

```bash
cargo xtask hook commit-msg --range origin/develop..HEAD
```
