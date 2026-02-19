# A05: Test Coverage Audit -- `src/lib/EVMOpcodes.sol`

## Source File Summary

`EVMOpcodes.sol` (184 lines) is a constants-only file defining 135 `uint8 constant` EVM opcode definitions (lines 5-175) and 1 `uint256 constant` derived bitmap `HALTING_BITMAP` (lines 177-183).

## Evidence of Thorough Reading

**Source file (`src/lib/EVMOpcodes.sol`):**
- 135 opcode constants from `EVM_OP_STOP` (0x00, line 5) through `EVM_OP_SELFDESTRUCT` (0xFF, line 175)
- `HALTING_BITMAP` (lines 178-183): composed of STOP, RETURN, REVERT, INVALID, SELFDESTRUCT, and JUMP

**Test file `test/lib/LibExtrospectBytecode.testConstants.sol`:**
- 24 lines, file-level constants (no contract wrapper)
- Defines `METAMORPHIC_METADATA` (line 10), `REPORTED_FALSE_POSITIVE` (line 16), `REPORTED_FALSE_POSITIVE_BYTECODE` (line 23) -- these are test fixture bytecode data, NOT constant value validation tests

**Test file `test/lib/LibExtrospectionSlow.sol`:**
- Library `LibExtrospectionSlow` (97 lines)
- Imports and uses `HALTING_BITMAP` (line 5, used line 48) and `EVM_OP_JUMPDEST` (line 5, used line 51)

**Test file `test/src/lib/LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode.t.sol`:**
- Contract `LibExtrospectScanEVMOpcodesReachableInBytecodeTest` (173 lines)
- Imports 11 EVM_OP_* constants (lines 9-19), uses them in shift-expression assertions

## Findings

### A05-F01 [LOW] No direct validation of 124 of 135 opcode constant values

Only 11 constants are referenced in tests. The remaining 124 opcode constant values are never validated against their expected hex values.

### A05-F02 [LOW] No direct test asserting the final computed value of `HALTING_BITMAP`

The `HALTING_BITMAP` is used in test reference implementations but its final computed value is never independently asserted.

### A05-F03 [LOW] JUMP (0x56) is in `HALTING_BITMAP` but has no dedicated halting test

Unlike STOP, RETURN, REVERT, INVALID, and SELFDESTRUCT, JUMP has no specific test demonstrating its halting behavior in the reachable scan.

### A05-F04 [INFO] File is current through Cancun hard fork

Pectra opcodes not included. This is expected for the current `evm_version = "cancun"` setting.
