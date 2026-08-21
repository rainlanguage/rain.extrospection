# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project

rain.extrospection is a Solidity library for analyzing EVM contract bytecode
onchain. It provides opcode scanning (present vs. reachable), ERC1167 minimal
proxy detection, ERC1967 beacon extrospection, Solidity CBOR metadata trimming,
and metamorphic risk detection. The library exposes onchain logic to offchain
tooling — the algorithms are gas-intensive and primarily intended for offchain
use.

License: LicenseRef-DCL-1.0 (DecentraLicense)

## Build & Test

Requires Nix with flakes enabled. The dev environment comes from the `rainix`
flake.

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

**Key pattern:** Opcodes are encoded as a single `uint256` bitmap where bit N
represents opcode 0xN. Bitwise AND against reference bitmaps checks for
(un)desired opcodes in one operation. `EVMOpcodes` defines one `EVM_OP_*`
constant per opcode defined through Cancun — 149 of the 256 byte values; the
rest are unassigned.

**Interfaces + libraries only:** this repo has no concrete contracts and no
deploy scripts. The concrete `Extrospect` implementation of `IExtrospectV1`, its
deploy pins (creation bytecode, deterministic Zoltu address, runtime codehash)
and the deploy tooling live in the rain.extrospection.deploy repo.

**Orphaned bitmaps:** `NON_STATIC_OPS` and `INTERPRETER_DISALLOWED_OPS` have no
consumer in `src/`. Only `test/src/lib/EVMOpcodes.t.sol` reads them, so a
search for consumers finds a hit and deleting them would break only that test.

**Test layout:** `test/src/` mirrors `src/` by subject path. Test files named
`Subject.functionName.t.sol`. `test/lib/` and `test/concrete/` are test-only
helpers, including slow reference implementations (`LibExtrospectionSlow`) used
for property-based fuzz verification.

## Conventions

- Solidity `^0.8.25` for libraries and interfaces, `=0.8.25` for concrete
  contracts (tests and test fixtures)
- Assembly blocks marked `memory-safe`
- Every file starts with SPDX license identifier and copyright header
- `forge-lint` annotations suppress expected warnings: `incorrect-shift`,
  `mixed-case-function`, `assembly-usage`
- Slither annotations suppress known false positives: `incorrect-shift`,
  `too-many-digits`
- Foundry config: optimizer on (100k runs), Cancun EVM, no CBOR metadata in
  output

## Dependencies

Soldeer packages, declared in `foundry.toml` `[dependencies]` and pinned in
`soldeer.lock`. `forge soldeer install` installs them under `dependencies/`
(`libs = ["dependencies"]`), which is gitignored. Imports carry the version in
the path, e.g. `rain-solmem-0.1.3/src/lib/LibBytes.sol`.

- `forge-std` 1.16.1 — Foundry test framework
- `rain-math-binary` 0.1.3 — Binary math utilities (`LibCtPop`)
- `rain-solmem` 0.1.3 — Memory utilities (`LibBytes`, `Pointer`)
