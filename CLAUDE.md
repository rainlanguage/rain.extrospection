# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

rain.extrospection is a Solidity library for analyzing EVM contract bytecode onchain. It provides opcode scanning (present vs. reachable), ERC1167 minimal proxy detection, Solidity CBOR metadata trimming, and interpreter safety validation. The library exposes onchain logic to offchain tooling — the algorithms are gas-intensive and primarily intended for offchain use.

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

**Source layout:** `src/lib/` for library implementations. No concrete deployed contracts — libraries only.

**Core libraries:**
- `LibExtrospectBytecode` — Opcode scanning (present scan: linear pass respecting PUSH\* inline data; reachable scan: halt-aware with JUMPDEST tracking), CBOR metadata trimming, EOF detection
- `LibExtrospectERC1167Proxy` — ERC1167 minimal proxy detection and implementation address extraction
- `LibExtrospectMetamorphic` — Metamorphic risk detection (scans for reachable SELFDESTRUCT, DELEGATECALL, CALLCODE, CREATE, CREATE2)
- `EVMOpcodes` — Constants for all 256 EVM opcodes and derived bitmaps (e.g. `HALTING_BITMAP`, `METAMORPHIC_OPS`)

**Key pattern:** Opcodes are encoded as a single `uint256` bitmap where bit N represents opcode 0xN. Bitwise AND against reference bitmaps checks for (un)desired opcodes in one operation.

**Test layout:** `test/src/lib/` mirrors source structure. Test files named `LibName.functionName.t.sol`. Test helpers in `test/lib/` include slow reference implementations (`LibExtrospectionSlow`) used for property-based fuzz verification.

## Conventions

- Solidity `^0.8.25` for non-concrete files (interfaces, libraries), `=0.8.25` for concrete files (tests)
- Assembly blocks marked `memory-safe`
- Every file starts with SPDX license identifier and copyright header
- `forge-lint` annotations suppress expected warnings: `incorrect-shift`, `mixed-case-function`, `assembly-usage`
- Slither annotations suppress known false positives: `incorrect-shift`, `too-many-digits`
- Foundry config: optimizer on (100k runs), Cancun EVM, no CBOR metadata in output

## Dependencies

Git submodules in `lib/`:
- `rain.solmem` — Memory utilities (`LibBytes`, `Pointer`)
- `rain.math.binary` — Binary math utilities
- `forge-std` — Foundry test framework
