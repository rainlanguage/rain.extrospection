# Pass 0: Process Review

## Documents Reviewed

- `foundry.toml` — Foundry build configuration
- `flake.nix` — Nix flake for development environment
- `README.md` — Project documentation
- `REUSE.toml` — License annotations
- `slither.config.json` — Static analysis configuration
- `.github/workflows/rainix.yaml` — CI workflow

No CLAUDE.md or other project-specific process documents exist.

## Findings

### A00-1 [INFO] No CLAUDE.md or project process documentation

There is no CLAUDE.md or equivalent project-specific process document. Future AI-assisted sessions have no guidance on:
- Code style conventions (e.g., naming patterns, assembly style)
- Test file naming and location conventions
- Security-sensitive areas requiring extra scrutiny
- Project-specific error handling patterns (e.g., custom errors vs revert strings)
- Dependency management approach (git submodules via lib/)

### A00-2 [LOW] CI workflow exposes deployment secrets on all branches

In `.github/workflows/rainix.yaml` line 14, `DEPLOYMENT_KEY` is set for all push events:
```yaml
DEPLOYMENT_KEY: ${{ github.ref == 'refs/heads/main' && secrets.PRIVATE_KEY || secrets.PRIVATE_KEY_DEV }}
```
While the conditional correctly uses `PRIVATE_KEY_DEV` for non-main branches, the environment variable name `DEPLOYMENT_KEY` is set unconditionally. Any CI task in the matrix (including `rainix-sol-test` and `rainix-sol-static`) has access to deployment key secrets even when they may not need them. Principle of least privilege suggests only providing deployment credentials to tasks that perform deployment.

### A00-3 [INFO] Slither excludes assembly-usage detector

`slither.config.json` excludes `assembly-usage`, `solc-version`, and `pragma` detectors and filters test and dependency paths. The `assembly-usage` exclusion is reasonable given this project is primarily assembly-based, but means Slither provides reduced coverage for the core logic. This is an inherent limitation worth noting.

### A00-4 [INFO] README typo

README.md line 43: "metdata" should be "metadata".
