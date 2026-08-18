# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

rain.extrospection is a Solidity library for analyzing EVM contract bytecode onchain. It provides opcode scanning (present vs. reachable), ERC1167 minimal proxy detection, ERC1967 beacon proxy extrospection, Solidity CBOR metadata trimming and hashing, and metamorphic risk detection. The libraries are exposed externally by one concrete contract, `Extrospect`, implementing `IExtrospectV1`. The library exposes onchain logic to offchain tooling — the algorithms are gas-intensive and primarily intended for offchain use.

License: LicenseRef-DCL-1.0 (DecentraLicense)

## Build & Test

Requires Nix with flakes enabled. The dev environment comes from the `rainix` flake.

```bash
# Enter dev shell
nix develop

# Setup step (must run before tests, both locally and in CI)
nix develop -c rainix-sol-prelude

# Run tests (2048 fuzz runs by default)
nix develop -c rainix-sol-test

# Static analysis (Slither)
nix develop -c rainix-sol-static

# License/legal checks
nix develop -c rainix-sol-legal

# Run forge directly inside nix shell
nix develop -c forge test
nix develop -c forge test --match-contract LibExtrospectBytecodeIsEOFBytecodeTest
nix develop -c forge test --match-test testFoo
```

## Architecture

**Source layout:** `src/lib/` for library implementations, `src/interface/` for interfaces, `src/concrete/` for the one deployed contract.

**Core libraries:**
- `LibExtrospectBytecode` — Opcode scanning (present scan: linear pass respecting PUSH\* inline data; reachable scan: halt-aware with JUMPDEST tracking), CBOR metadata trimming and trimmed-hash checks, EOF detection
- `LibExtrospectERC1167Proxy` — ERC1167 minimal proxy detection and implementation address extraction
- `LibExtrospectERC1967BeaconProxy` — Beacon implementation-bytecode and owner checks, plus the ERC1967 slot constants
- `LibExtrospectMetamorphic` — Metamorphic risk detection (scans for reachable SELFDESTRUCT, DELEGATECALL, CALLCODE, CREATE, CREATE2)
- `EVMOpcodes` — One `EVM_OP_*` constant per opcode defined through Cancun (149 of the 256 byte values; the rest are unassigned) and derived bitmaps: `HALTING_BITMAP`, `METAMORPHIC_OPS`, `NON_STATIC_OPS`, `INTERPRETER_DISALLOWED_OPS`

**Concrete contract:** `Extrospect` implements `IExtrospectV1`, forwarding each function to the library function of the same name. Its constructor takes no arguments, and `Extrospect.sol` pins the creation bytecode, deterministic Zoltu address and runtime codehash as constants that `script/Deploy.sol` and `test/src/concrete/Extrospect.constants.t.sol` both read.

**Orphaned bitmaps:** `NON_STATIC_OPS` and `INTERPRETER_DISALLOWED_OPS` have no consumer in `src/` — no library, interface or deployed function reads them. They are exported for callers to mask against a reachable scan themselves, and only `test/src/lib/EVMOpcodes.t.sol` references them in-repo.

**Key pattern:** Opcodes are encoded as a single `uint256` bitmap where bit N represents opcode 0xN. Bitwise AND against reference bitmaps checks for (un)desired opcodes in one operation.

**Test layout:** `test/src/` mirrors source structure by subject path, so `test/src/lib/` covers `src/lib/` and `test/src/concrete/` covers `src/concrete/`. Test files named `Subject.functionName.t.sol`. `test/lib/` holds test-only libraries, including slow reference implementations (`LibExtrospectionSlow`) used for property-based fuzz verification, and `test/concrete/` holds test-only contracts used as fixtures.

## Conventions

- Solidity `^0.8.25` for non-concrete files (libraries), `=0.8.25` for concrete files (tests)
- Assembly blocks marked `memory-safe`
- Every file starts with SPDX license identifier and copyright header
- `forge-lint` annotations suppress expected warnings: `incorrect-shift`, `mixed-case-function`, `assembly-usage`
- Slither annotations suppress known false positives: `incorrect-shift`, `too-many-digits`
- Foundry config: optimizer on (100k runs), Cancun EVM, no CBOR metadata in output

## Dependencies

Soldeer packages, declared in `foundry.toml` `[dependencies]` and pinned in `soldeer.lock`. `forge soldeer install` installs them under `dependencies/` (`libs = ["dependencies"]`), which is gitignored. Imports carry the version in the path, e.g. `rain-solmem-0.1.3/src/lib/LibBytes.sol`.

- `forge-std` 1.16.1 — Foundry test framework
- `rain-deploy` 0.1.3 — Deployment helpers (`LibRainDeploy`), used by `script/Deploy.sol`
- `rain-math-binary` 0.1.3 — Binary math utilities (`LibCtPop`)
- `rain-solmem` 0.1.3 — Memory utilities (`LibBytes`, `Pointer`)
