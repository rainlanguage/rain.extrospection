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

# Mutation / coverage campaigns (drops the deploy-constant pins)
nix develop -c bash -c 'FOUNDRY_PROFILE=mutation forge test'
```

### The `mutation` profile

`ExtrospectConstantsTest` (`test/src/concrete/Extrospect.constants.t.sol`) pins `type(Extrospect).creationCode` and `type(Extrospect).runtimeCode` against the `EXTROSPECT_*_V1` constants. Those compiler outputs change for any edit to any source file reachable from `Extrospect`, so both pins fail under every source mutation, whether or not the mutated behaviour is observable. Under the default profile a mutation campaign therefore scores every mutant `KILLED` and measures nothing.

`FOUNDRY_PROFILE=mutation` runs the same suite with `no_match_contract = "ExtrospectConstantsTest"`. Every mutation or coverage campaign on this repo runs under it. The default profile keeps the pins, so CI and releases still catch constant drift.

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
