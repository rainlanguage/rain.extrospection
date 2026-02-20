# Pass 2: Test Coverage — A04 — IExtrospectMetamorphicV1

## Evidence of Thorough Reading

**Interface name:** `IExtrospectMetamorphicV1` (line 11)

**Functions:**

| Function | Line |
|----------|------|
| `scanMetamorphicRisk(address account) external view returns (uint256 riskyOpcodes)` | 16 |

**Related constant:** `METAMORPHIC_OPS` (defined in `src/lib/EVMOpcodes.sol`). Five bits: SELFDESTRUCT, DELEGATECALL, CALLCODE, CREATE, CREATE2.

## Test Files Examined

| File | Covers |
|------|--------|
| `test/src/interface/IExtrospectMetamorphicV1.t.sol` | `METAMORPHIC_OPS` constant correctness |
| `test/src/lib/LibExtrospectMetamorphic.scanMetamorphicRisk.t.sol` | Library-level scanning logic |
| `test/src/lib/LibExtrospectMetamorphic.checkNotMetamorphic.t.sol` | Library-level guard function |

The interface test file contains four tests focused on the `METAMORPHIC_OPS` constant. All tests of scanning call `LibExtrospectMetamorphic.scanMetamorphicRisk(bytes memory)` directly. No test calls through `IExtrospectMetamorphicV1.scanMetamorphicRisk(address)`.

## Findings

### A04-1: No end-to-end test of `scanMetamorphicRisk(address)` through the interface — **MEDIUM**

The interface declares `scanMetamorphicRisk(address account)`. Every test calls the library function directly with `address(c).code` as raw bytes. No test deploys a contract implementing `IExtrospectMetamorphicV1` and exercises the address-based calling convention.

### A04-2: `testMetamorphicOpsExclusions` checks only 3 of 251 non-member opcode bytes — **LOW**

`testMetamorphicOpsExclusions` verifies that STATICCALL, CALL, and RETURN are absent from `METAMORPHIC_OPS`. The popcount test partially compensates but does not identify which specific bits are unintentionally set in the event of a regression.
