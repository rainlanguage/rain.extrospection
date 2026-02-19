# A06: Test Coverage Audit -- `src/lib/LibExtrospectBytecode.sol`

## Source File Summary

`LibExtrospectBytecode.sol` (213 lines) is a library with 6 functions and 3 custom errors:

**Errors:**
- `MetadataNotTrimmed()` (line 16)
- `EOFBytecodeNotSupported()` (line 19)
- `BytecodeHashMismatch(bytes32 expected, bytes32 actual)` (line 24)

**Functions:**
1. `isEOFBytecode(bytes memory)` -- line 29, internal pure, returns bool
2. `checkNotEOFBytecode(bytes memory)` -- line 41, internal pure, reverts if EOF
3. `tryTrimSolidityCBORMetadata(bytes memory)` -- line 90, internal pure, returns bool
4. `checkCBORTrimmedBytecodeHash(address, bytes32)` -- line 117, internal view
5. `scanEVMOpcodesReachableInBytecode(bytes memory)` -- line 135, internal pure, returns uint256
6. `scanEVMOpcodesPresentInBytecode(bytes memory)` -- line 190, internal pure, returns uint256

## Evidence of Thorough Reading

**Test file `LibExtrospectBytecode.isEOFBytecode.t.sol` (51 lines):**
- Contract: `LibExtrospectBytecodeIsEOFBytecodeTest`
- `testIsEOFBytecodeEmpty()` line 17 -- empty bytecode
- `testIsEOFBytecodeSingleByte()` line 22 -- single byte 0xEF
- `testIsEOFBytecodeNonEOF()` line 27 -- normal bytecode
- `testIsEOFBytecodeEOF()` line 32 -- valid EOF
- `testCheckNotEOFBytecodeRevertsOnEOF()` line 37 -- revert path
- `testCheckNotEOFBytecodeDoesNotRevertOnNonEOF()` line 43 -- non-revert path
- `testIsEOFBytecodeFuzz(bytes memory)` line 48 -- fuzz against slow reference

**Test file `LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode.t.sol` (42 lines):**
- Contract: `LibExtrospectBytecodeScanEVMOpcodesPresentInBytecodeTest`
- `testScanEVMOpcodesPresentSimple()` line 18
- `testScanEVMOpcodesPresentPush1()` line 22
- `testScanEVMOpcodesPresentReference(bytes memory)` line 28 -- fuzz
- `testScanEVMOpcodesPresentRevertsOnEOF()` line 37

**Test file `LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode.t.sol` (172 lines):**
- Contract: `LibExtrospectScanEVMOpcodesReachableInBytecodeTest`
- 15 test functions covering: simple opcodes, each halting opcode, JUMPDEST resumption, PUSH skip logic, PUSH while halted, real-world bytecodes (false positives, metamorphic metadata), fuzz against reference, EOF revert

**Test file `LibExtrospectBytecode.tryTrimSolidityCBORMetadata.t.sol` (75 lines):**
- Contract: `LibExtrospectBytecodeTryTrimSolidityCBORMetadataTest`
- `testTryTrimSolidityCBORMetadataBytecodeShort(bytes memory)` line 14 -- fuzz short bytecode
- `testTryTrimSolidityCBORMetdataBytecodeReal()` line 20 -- real bytecode
- `testTryTrimSolidityCBORMetadataBytecodeContrived(bytes memory)` line 32 -- fuzz, constructs metadata
- `testTryTrimSolidityCBORMetadataRevertsOnEOF()` line 70

**Test file `LibExtrospectBytecode.checkCBORTrimmedBytecodeHash.t.sol` (54 lines):**
- Contract: `LibExtrospectBytecodeCheckCBORTrimmedBytecodeHashTest`
- `testCheckCBORTrimmedBytecodeHashSuccess()` line 18 -- happy path (requires Arbitrum fork)
- `testCheckCBORTrimmedBytecodeHashFailure()` line 26 -- hash mismatch revert
- `testCheckCBORTrimmedBytecodeHashMetadataNotTrimmed()` line 40 -- metadata not trimmed revert

**Test file `test/lib/LibExtrospectionSlow.sol` (97 lines):**
- Library `LibExtrospectionSlow` with 3 slow reference implementations:
  - `isEOFBytecodeSlow` (line 11)
  - `scanEVMOpcodesPresentInBytecodeSlow` (line 23)
  - `scanEVMOpcodesReachableInBytecodeSlow` (line 38)

## Function Coverage Matrix

| Function | Test File | Tests | Fuzz | Errors Tested | Empty Input | EOF Revert |
|----------|-----------|-------|------|---------------|-------------|------------|
| `isEOFBytecode` | isEOFBytecode.t.sol | 4 unit + 1 fuzz | Yes | N/A | Yes | N/A |
| `checkNotEOFBytecode` | isEOFBytecode.t.sol | 2 unit | No | EOFBytecodeNotSupported | No | Yes |
| `tryTrimSolidityCBORMetadata` | tryTrimSolidityCBORMetadata.t.sol | 1 unit + 2 fuzz | Yes | EOFBytecodeNotSupported | No (fuzz < 53) | Yes |
| `checkCBORTrimmedBytecodeHash` | checkCBORTrimmedBytecodeHash.t.sol | 3 unit | No | MetadataNotTrimmed, BytecodeHashMismatch | No | No (indirect) |
| `scanEVMOpcodesReachableInBytecode` | scanEVMOpcodesReachableInBytecode.t.sol | 12 unit + 1 fuzz | Yes | EOFBytecodeNotSupported | No | Yes |
| `scanEVMOpcodesPresentInBytecode` | scanEVMOpcodesPresentInBytecode.t.sol | 2 unit + 1 fuzz | Yes | EOFBytecodeNotSupported | No | Yes |

## Findings

### A06-F01 [MEDIUM] No test for empty bytecode on `scanEVMOpcodesPresentInBytecode`

The `scanEVMOpcodesPresentInBytecode` function has no explicit test for empty (zero-length) bytecode input. While the fuzz test could randomly generate empty input, it is not guaranteed. Empty bytecode is a boundary condition for the assembly loop at line 197, where `cursor` would equal `end` and the loop would not execute. The function should return 0.

### A06-F02 [MEDIUM] No test for empty bytecode on `scanEVMOpcodesReachableInBytecode`

Same as A06-F01 but for the reachability scanner. No explicit test for empty bytecode. The assembly loop at line 146 would not execute, and the function would return 0. Should be explicitly verified.

### A06-F03 [MEDIUM] No test for truncated PUSH data at end of bytecode

When a PUSH opcode appears at the very end of bytecode (or near the end such that its data extends past the bytecode boundary), the scanner skips past `cursor + push_size + 1` which may exceed `end`. There are no tests specifically targeting:
- PUSH1 as the last byte (no data byte following)
- PUSH32 as the last byte (31 bytes short of data)
- PUSH32 with only 1 byte of data following

The `lt(cursor, end)` guard prevents further iterations, so the overshoot is benign, and fuzz tests comparing against the slow reference should catch any divergence. However, explicit edge case tests would provide stronger guarantees.

### A06-F04 [LOW] No single-byte bytecode tests for scanning functions

While `isEOFBytecode` has explicit single-byte tests, the scanning functions have no explicit single-byte tests. A single non-PUSH opcode (e.g., `hex"01"`) or a single PUSH opcode (e.g., `hex"60"`) are not tested explicitly.

### A06-F05 [LOW] No test for exactly 53-byte bytecode in `tryTrimSolidityCBORMetadata`

The function checks `length >= 53` (line 93). There is a fuzz test for `length < 53`, but no explicit test for bytecode that is exactly 53 bytes long (the entire bytecode IS the metadata with no code prefix). The contrived fuzz test covers this indirectly since fuzz input could be empty, but it is not guaranteed.

### A06-F06 [LOW] No idempotency test for `tryTrimSolidityCBORMetadata`

No test verifies that calling `tryTrimSolidityCBORMetadata` twice on the same bytecode returns `false` on the second call (after the first call trimmed it).

### A06-F07 [INFO] `checkCBORTrimmedBytecodeHash` tests depend on Arbitrum fork RPC

All three tests require a fork of Arbitrum via `LibExtrospectTestProd.createSelectForkArbitrum(vm)`. If the fork is unavailable, these tests fail for infrastructure reasons.

### A06-F08 [LOW] No test for `checkCBORTrimmedBytecodeHash` with empty account

No test for when the target address has no deployed code (EOA or empty account). The function would revert with `MetadataNotTrimmed()`.

### A06-F09 [INFO] Slow reference logic order matches assembly -- confirmed equivalent

The slow reference `scanEVMOpcodesReachableInBytecodeSlow` independently processes PUSH skip and halting logic in the same order as the assembly implementation. Fuzz test confirms equivalence.
