# Pass 2: Test Coverage — A07 — LibExtrospectBytecode

## Evidence of Thorough Reading

### Source file: `src/lib/LibExtrospectBytecode.sol`

**Errors:** `MetadataNotTrimmed` (16), `EOFBytecodeNotSupported` (19), `BytecodeHashMismatch` (24), `UnexpectedMetadata` (29)

**Functions:** `isEOFBytecode` (34), `checkNotEOFBytecode` (46), `tryTrimSolidityCBORMetadata` (96), `checkCBORTrimmedBytecodeHash` (123), `checkNoSolidityCBORMetadata` (142), `scanEVMOpcodesReachableInBytecode` (156), `scanEVMOpcodesPresentInBytecode` (209)

### Test files examined (6 files, ~120 test functions total)

- `LibExtrospectBytecode.isEOFBytecode.t.sol` — 7 tests
- `LibExtrospectBytecode.tryTrimSolidityCBORMetadata.t.sol` — 7 tests
- `LibExtrospectBytecode.checkCBORTrimmedBytecodeHash.t.sol` — 4 tests
- `LibExtrospectBytecode.checkNoSolidityCBORMetadata.t.sol` — 3 tests
- `LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode.t.sol` — ~85 tests
- `LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode.t.sol` — ~76 tests

All 7 source functions are tested. All 4 errors are exercised. Fuzz tests with reference implementations exist for both scanners. Extensive source-contract tests cover ~50 opcodes.

## Findings

### A07-1: No explicit unit test for PUSH0 (0x5F) boundary in either scan function — **LOW**

PUSH0 sits exactly one byte below the PUSH1–PUSH32 range (0x60–0x7F). The `sub(op, 0x60)` underflow for 0x5F correctly results in no data skip, but no deterministic test validates this boundary. A future refactor of PUSH-range detection could break this without the fuzz test catching it in every run.

### A07-2: No explicit unit test for JUMPI not halting the reachable scan — **INFO**

`JUMPI` (0x57) is intentionally excluded from `HALTING_BITMAP` because it may fall through. No unit test directly exercises JUMPI followed by further opcodes to assert they remain reachable. The fuzz test provides probabilistic coverage.
