# Pass 0: Process Review — 2026-02-20-02

## Documents Reviewed

- `CLAUDE.md` (66 lines)
- `foundry.toml` (14 lines)
- `.github/workflows/rainix.yaml` (33 lines)

## Findings

### P0-1 | LOW | CLAUDE.md conventions reference "interfaces" but none exist

Line 53: `Solidity ^0.8.25 for non-concrete files (interfaces, libraries)` — all interface files were removed in audit 2026-02-20-01. The parenthetical "(interfaces, libraries)" is now misleading and could confuse a future session into recreating interface files.

### P0-2 | LOW | CLAUDE.md test layout description incomplete

Line 49 describes test layout as `test/src/lib/` mirroring source structure, but omits `test/src/interface/` which contains two test files (`IExtrospectInterpreterV1.t.sol`, `IExtrospectMetamorphicV1.t.sol`). These test bitmap constants now defined in `EVMOpcodes.sol` but their file names still reference deleted interfaces. A future session looking for bitmap constant tests would not find them by following the documented layout.

### P0-3 | LOW | Test files named after deleted interfaces

`test/src/interface/IExtrospectInterpreterV1.t.sol` and `test/src/interface/IExtrospectMetamorphicV1.t.sol` test constants (`INTERPRETER_DISALLOWED_OPS`, `NON_STATIC_OPS`, `METAMORPHIC_OPS`) that now live in `src/lib/EVMOpcodes.sol`. The file names and directory placement reference interfaces that no longer exist. This creates a mapping mismatch: source is `EVMOpcodes.sol` but tests are split across `EVMOpcodes.t.sol` and two interface-named files.

### P0-4 | INFO | CI workflow contains unused deployment environment variables

`.github/workflows/rainix.yaml` sets `DEPLOYMENT_KEY`, `ETH_RPC_URL`, `ETHERSCAN_API_KEY`, `DEPLOY_VERIFIER`, and `RPC_URL_ARBITRUM_FORK`. This repo has no deployment scripts or deployable contracts. These appear inherited from a shared CI template.
