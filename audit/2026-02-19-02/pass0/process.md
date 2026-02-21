# Pass 0: Process Review

Audit namespace: `2026-02-19-02`

## Documents Reviewed

- `CLAUDE.md` (66 lines)
- `foundry.toml` (15 lines)
- `flake.nix` (19 lines)
- No `.cursorrules`, `.cursor/rules/`, or `.github/copilot-instructions.md` found

## Findings

### A00-1 [LOW] CLAUDE.md `rainix-sol-prelude` ordering is ambiguous

**Line 29:** The setup step `rainix-sol-prelude` is documented after the test/static/legal commands, with the comment "Setup step (run before tests in CI)". The parenthetical "(run before tests in CI)" could lead a future session to interpret this as CI-only, skipping it in local development. If it is required locally as well, it should be listed first with a clear note. If it is CI-only, it should be labeled as such without ambiguity.

### A00-2 [INFO] CLAUDE.md does not mention security-sensitive patterns for this codebase

CLAUDE.md describes the architecture and conventions but does not call out security-critical areas a future session should be especially careful with, such as:
- Assembly memory safety assumptions in `LibExtrospectBytecode`
- The trust model (bytecode analysis results are only as reliable as the scanning algorithm)
- That `tryTrimSolidityCBORMetadata` mutates bytecode in place

These are documented in the source code comments but a future session modifying these files may not read the full source before making changes if CLAUDE.md doesn't flag them.

### A00-3 [INFO] No guidance on submodule update workflow

CLAUDE.md lists dependencies as git submodules but doesn't document how to initialize or update them. The CI workflow uses `submodules: recursive` in the checkout step, but a future session doing local development might not know to run `git submodule update --init --recursive`.

### A00-4 [INFO] CLAUDE.md `IExtrospectInterpreterV1` not mentioned in architecture

The Architecture section lists `LibExtrospectBytecode`, `LibExtrospectERC1167Proxy`, and `EVMOpcodes` as core libraries but does not mention `IExtrospectInterpreterV1` — an interface that defines interpreter safety validation constraints. This is referenced in the project description ("interpreter safety validation") but the architecture section doesn't explain it, which could cause confusion about where that functionality lives.
