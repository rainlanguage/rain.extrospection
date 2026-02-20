# Security Audit: EVMOpcodes.sol

**Auditor:** A01
**Date:** 2026-02-20
**File:** `src/lib/EVMOpcodes.sol` (246 lines)
**Commit branch:** 2026-02-19-metamorphic

---

## Evidence of Thorough Reading

### Module/Contract Name

This file defines no contract, library, or interface. It is a file-level constants module used by `LibExtrospectBytecode`, `LibExtrospectMetamorphic`, and test files. All symbols are `uint8 constant` or `uint256 constant` at file scope.

### Constants Defined (135 opcode constants + 4 bitmap constants = 139 total)

**Arithmetic (lines 12-24):**
- `EVM_OP_STOP` = 0x00 (line 12)
- `EVM_OP_ADD` = 0x01 (line 14)
- `EVM_OP_MUL` = 0x02 (line 15)
- `EVM_OP_SUB` = 0x03 (line 16)
- `EVM_OP_DIV` = 0x04 (line 17)
- `EVM_OP_SDIV` = 0x05 (line 18)
- `EVM_OP_MOD` = 0x06 (line 19)
- `EVM_OP_SMOD` = 0x07 (line 20)
- `EVM_OP_ADDMOD` = 0x08 (line 21)
- `EVM_OP_MULMOD` = 0x09 (line 22)
- `EVM_OP_EXP` = 0x0A (line 23)
- `EVM_OP_SIGNEXTEND` = 0x0B (line 24)

**Comparison (lines 26-31):**
- `EVM_OP_LT` = 0x10 (line 26)
- `EVM_OP_GT` = 0x11 (line 27)
- `EVM_OP_SLT` = 0x12 (line 28)
- `EVM_OP_SGT` = 0x13 (line 29)
- `EVM_OP_EQ` = 0x14 (line 30)
- `EVM_OP_ISZERO` = 0x15 (line 31)

**Bitwise/Shift (lines 33-40):**
- `EVM_OP_AND` = 0x16 (line 33)
- `EVM_OP_OR` = 0x17 (line 34)
- `EVM_OP_XOR` = 0x18 (line 35)
- `EVM_OP_NOT` = 0x19 (line 36)
- `EVM_OP_BYTE` = 0x1A (line 37)
- `EVM_OP_SHL` = 0x1B (line 38)
- `EVM_OP_SHR` = 0x1C (line 39)
- `EVM_OP_SAR` = 0x1D (line 40)

**Hashing (line 42):**
- `EVM_OP_SHA3` = 0x20 (line 42)

**Environmental (lines 44-65):**
- `EVM_OP_ADDRESS` = 0x30 (line 44)
- `EVM_OP_BALANCE` = 0x31 (line 45)
- `EVM_OP_ORIGIN` = 0x32 (line 47)
- `EVM_OP_CALLER` = 0x33 (line 48)
- `EVM_OP_CALLVALUE` = 0x34 (line 49)
- `EVM_OP_CALLDATALOAD` = 0x35 (line 50)
- `EVM_OP_CALLDATASIZE` = 0x36 (line 51)
- `EVM_OP_CALLDATACOPY` = 0x37 (line 52)
- `EVM_OP_CODESIZE` = 0x38 (line 54)
- `EVM_OP_CODECOPY` = 0x39 (line 55)
- `EVM_OP_GASPRICE` = 0x3A (line 57)
- `EVM_OP_EXTCODESIZE` = 0x3B (line 59)
- `EVM_OP_EXTCODECOPY` = 0x3C (line 60)
- `EVM_OP_RETURNDATASIZE` = 0x3D (line 62)
- `EVM_OP_RETURNDATACOPY` = 0x3E (line 63)
- `EVM_OP_EXTCODEHASH` = 0x3F (line 65)

**Block Information (lines 66-79):**
- `EVM_OP_BLOCKHASH` = 0x40 (line 66)
- `EVM_OP_COINBASE` = 0x41 (line 68)
- `EVM_OP_TIMESTAMP` = 0x42 (line 69)
- `EVM_OP_NUMBER` = 0x43 (line 70)
- `EVM_OP_DIFFICULTY` = 0x44 (line 71)
- `EVM_OP_GASLIMIT` = 0x45 (line 72)
- `EVM_OP_CHAINID` = 0x46 (line 73)
- `EVM_OP_SELFBALANCE` = 0x47 (line 75)
- `EVM_OP_BASEFEE` = 0x48 (line 77)
- `EVM_OP_BLOBHASH` = 0x49 (line 78)
- `EVM_OP_BLOBBASEFEE` = 0x4A (line 79)

**Stack/Memory/Storage/Flow (lines 81-98):**
- `EVM_OP_POP` = 0x50 (line 81)
- `EVM_OP_MLOAD` = 0x51 (line 82)
- `EVM_OP_MSTORE` = 0x52 (line 83)
- `EVM_OP_MSTORE8` = 0x53 (line 84)
- `EVM_OP_SLOAD` = 0x54 (line 86)
- `EVM_OP_SSTORE` = 0x55 (line 87)
- `EVM_OP_JUMP` = 0x56 (line 89)
- `EVM_OP_JUMPI` = 0x57 (line 90)
- `EVM_OP_PC` = 0x58 (line 91)
- `EVM_OP_MSIZE` = 0x59 (line 92)
- `EVM_OP_GAS` = 0x5A (line 93)
- `EVM_OP_JUMPDEST` = 0x5B (line 94)
- `EVM_OP_TLOAD` = 0x5C (line 95)
- `EVM_OP_TSTORE` = 0x5D (line 96)
- `EVM_OP_MCOPY` = 0x5E (line 97)

**PUSH (lines 99-131):**
- `EVM_OP_PUSH0` = 0x5F (line 99)
- `EVM_OP_PUSH1` through `EVM_OP_PUSH32` = 0x60 through 0x7F (lines 100-131)

**DUP (lines 133-148):**
- `EVM_OP_DUP1` through `EVM_OP_DUP16` = 0x80 through 0x8F (lines 133-148)

**SWAP (lines 150-165):**
- `EVM_OP_SWAP1` through `EVM_OP_SWAP16` = 0x90 through 0x9F (lines 150-165)

**LOG (lines 167-171):**
- `EVM_OP_LOG0` through `EVM_OP_LOG4` = 0xA0 through 0xA4 (lines 167-171)

**System/Call (lines 173-182):**
- `EVM_OP_CREATE` = 0xF0 (line 173)
- `EVM_OP_CALL` = 0xF1 (line 174)
- `EVM_OP_CALLCODE` = 0xF2 (line 175)
- `EVM_OP_RETURN` = 0xF3 (line 176)
- `EVM_OP_DELEGATECALL` = 0xF4 (line 177)
- `EVM_OP_CREATE2` = 0xF5 (line 178)
- `EVM_OP_STATICCALL` = 0xFA (line 179)
- `EVM_OP_REVERT` = 0xFD (line 180)
- `EVM_OP_INVALID` = 0xFE (line 181)
- `EVM_OP_SELFDESTRUCT` = 0xFF (line 182)

**Derived Bitmaps (lines 189-245):**
- `HALTING_BITMAP` (line 189): uint256
- `METAMORPHIC_OPS` (line 206): uint256
- `NON_STATIC_OPS` (line 218): uint256
- `INTERPRETER_DISALLOWED_OPS` (line 232): uint256

### Types and Errors Defined

None. This file contains only file-level constants.

---

## Opcode Value Verification Against EVM Specification

All 135 opcode constants were verified against the canonical Ethereum Yellow Paper and the ethereum/execution-specs opcode table (Cancun-era). Every value is correct:

- 0x00 (STOP) through 0x0B (SIGNEXTEND): Correct
- 0x10 (LT) through 0x1D (SAR): Correct
- 0x20 (SHA3): Correct
- 0x30 (ADDRESS) through 0x3F (EXTCODEHASH): Correct
- 0x40 (BLOCKHASH) through 0x4A (BLOBBASEFEE): Correct
- 0x50 (POP) through 0x5E (MCOPY): Correct
- 0x5F (PUSH0) through 0x7F (PUSH32): Correct
- 0x80 (DUP1) through 0x8F (DUP16): Correct
- 0x90 (SWAP1) through 0x9F (SWAP16): Correct
- 0xA0 (LOG0) through 0xA4 (LOG4): Correct
- 0xF0 (CREATE) through 0xFF (SELFDESTRUCT): Correct, including the gap (0xF6-0xF9 and 0xFB-0xFC not defined, which is correct)

---

## Bitmap Verification

### HALTING_BITMAP (lines 188-194)

**Declared members:** STOP (0x00), RETURN (0xF3), REVERT (0xFD), INVALID (0xFE), SELFDESTRUCT (0xFF), JUMP (0x56)

**Verification:**
- `1 << 0x00` = bit 0: STOP -- Correct. STOP halts execution.
- `1 << 0xF3` = bit 243: RETURN -- Correct. RETURN halts execution.
- `1 << 0xFD` = bit 253: REVERT -- Correct. REVERT halts execution.
- `1 << 0xFE` = bit 254: INVALID -- Correct. INVALID halts execution.
- `1 << 0xFF` = bit 255: SELFDESTRUCT -- Correct. SELFDESTRUCT halts execution.
- `1 << 0x56` = bit 86: JUMP -- Correct. Unconditional JUMP cannot fall through; the next instruction is unreachable unless it is a JUMPDEST reached from elsewhere.

**Shift safety:** All shift amounts are 0-255, which is within the 256-bit range of uint256. No overflow possible.

**Design note:** JUMPI (0x57) is correctly excluded because conditional jumps can fall through.

**Popcount:** 6 bits set. Verified independently in test `testHaltingBitmapPopcount`.

**Result:** Correct.

### METAMORPHIC_OPS (lines 205-210)

**Declared members:** SELFDESTRUCT (0xFF), DELEGATECALL (0xF4), CALLCODE (0xF2), CREATE (0xF0), CREATE2 (0xF5)

**Verification:**
- `1 << 0xFF` = bit 255: SELFDESTRUCT -- Correct. Direct destruction enables metamorphism.
- `1 << 0xF4` = bit 244: DELEGATECALL -- Correct. Can execute SELFDESTRUCT in caller context.
- `1 << 0xF2` = bit 242: CALLCODE -- Correct. Deprecated equivalent of DELEGATECALL.
- `1 << 0xF0` = bit 240: CREATE -- Correct. Can deploy child contracts.
- `1 << 0xF5` = bit 245: CREATE2 -- Correct. Can deploy at deterministic addresses.

**Shift safety:** All shift amounts (0xF0-0xFF) are within uint256 range.

**Popcount:** 5 bits set.

**Result:** Correct.

### NON_STATIC_OPS (lines 217-228)

**Declared members per EIP-214:** CREATE (0xF0), CREATE2 (0xF5), LOG0-LOG4 (0xA0-0xA4), SSTORE (0x55), SELFDESTRUCT (0xFF), CALL (0xF1), TSTORE (0x5D)

**Verification against EIP-214 specification:**

EIP-214 disallows in static context: CREATE, CREATE2, LOG0-LOG4, SSTORE, SELFDESTRUCT, and CALL with non-zero value.

- `1 << 0xF0` = CREATE -- Correct per EIP-214.
- `1 << 0xF5` = CREATE2 -- Correct per EIP-214.
- `1 << 0xA0` through `1 << 0xA4` = LOG0-LOG4 -- Correct per EIP-214.
- `1 << 0x55` = SSTORE -- Correct per EIP-214.
- `1 << 0xFF` = SELFDESTRUCT -- Correct per EIP-214.
- `1 << 0xF1` = CALL -- Included unconditionally. The comment on line 213-215 correctly documents that the bitmap cannot express the value-conditional semantics (EIP-214 only disallows CALL with non-zero value). This is a conservative over-approximation.
- `1 << 0x5D` = TSTORE -- Correct per EIP-1153/EIP-7569 (Cancun). TSTORE is state-modifying and disallowed in static context.

**Shift safety:** All shift amounts within uint256 range.

**Popcount:** 11 bits set (CREATE, CREATE2, LOG0, LOG1, LOG2, LOG3, LOG4, SSTORE, SELFDESTRUCT, CALL, TSTORE).

**Result:** Correct.

### INTERPRETER_DISALLOWED_OPS (lines 230-245)

**Declared as:** NON_STATIC_OPS | SLOAD | TLOAD | DELEGATECALL | CALLCODE

**Verification:**
- Inherits all 11 bits from NON_STATIC_OPS: Correct.
- `1 << 0x54` = SLOAD -- Added because interpreter cannot SSTORE so should not SLOAD.
- `1 << 0x5C` = TLOAD -- Added because interpreter cannot TSTORE so should not TLOAD.
- `1 << 0xF4` = DELEGATECALL -- Added because it could mutate interpreter state.
- `1 << 0xF2` = CALLCODE -- Added because interpreter must use STATICCALL only.

**Shift safety:** All shift amounts within uint256 range.

**Popcount:** 15 bits set (11 from NON_STATIC_OPS + SLOAD, TLOAD, DELEGATECALL, CALLCODE).

**Result:** Correct.

---

## Security Findings

### A01-1: HALTING_BITMAP uses uint8 without explicit cast to uint256 in shift expressions [INFO]

**Location:** Lines 189-194

**Description:** In `HALTING_BITMAP`, the shift expressions use `(1 << EVM_OP_STOP)` where `EVM_OP_STOP` is `uint8`. In contrast, `METAMORPHIC_OPS`, `NON_STATIC_OPS`, and `INTERPRETER_DISALLOWED_OPS` use explicit `uint256()` casts such as `(1 << uint256(EVM_OP_SELFDESTRUCT))`.

The behavior is identical in Solidity: the literal `1` is inferred as `uint256` (since the result is assigned to a `uint256`), and the `uint8` shift amount is implicitly widened. However, the inconsistency is a code quality concern. If a future change were to alter the type inference context, the lack of explicit cast could theoretically lead to unexpected behavior, though this is extremely unlikely with current Solidity semantics.

**Impact:** None. Solidity semantics guarantee correct behavior regardless.

**Recommendation:** For consistency, consider adding explicit `uint256()` casts in `HALTING_BITMAP` to match the other bitmaps, or remove the casts from the other bitmaps.

### A01-2: DIFFICULTY opcode is post-Merge PREVRANDAO alias [INFO]

**Location:** Line 71

**Description:** The constant `EVM_OP_DIFFICULTY` at 0x44 is correctly defined per the original EVM specification. Post-Merge (Paris upgrade), this opcode was repurposed as PREVRANDAO (EIP-4399). The constant name `EVM_OP_DIFFICULTY` retains the pre-Merge name. This is not incorrect -- the opcode byte value 0x44 is the same regardless of the name -- but could be confusing in a post-Merge context.

**Impact:** None. The value is correct; only the name could cause confusion.

**Recommendation:** Consider adding a comment noting the PREVRANDAO alias, or defining an alias constant `EVM_OP_PREVRANDAO = 0x44`.

### A01-3: NON_STATIC_OPS includes CALL unconditionally -- conservative over-approximation [INFO]

**Location:** Lines 213-215, 226

**Description:** EIP-214 only disallows CALL when `value != 0`. The bitmap includes CALL unconditionally because a single-bit bitmap cannot express value-conditional semantics. This is correctly documented in the NatSpec. The consequence is that any bytecode containing a reachable CALL opcode will be flagged as having non-static operations, even if all CALL invocations pass zero value. This is a safe over-approximation but could produce false positives.

**Impact:** False positives when scanning for static-safe bytecode. No false negatives (no security risk).

**Recommendation:** No change needed. The documentation is clear. Consumers of this bitmap should be aware of this over-approximation.

### A01-4: No coverage of Pectra/Prague opcodes [INFO]

**Location:** Entire file (lines 5-10 document "current through Cancun")

**Description:** The file documents itself as current through the Cancun hard fork. Post-Cancun opcodes introduced in Pectra/Prague (e.g., AUTH 0xF6, AUTHCALL 0xF7 from EIP-3074, or EOF-related opcodes from EIP-7692) are not included. If the target chain has activated these opcodes, the bitmaps may be incomplete. Notably:
- AUTHCALL (0xF7, if activated via EIP-3074) would be a state-modifying call opcode that should potentially be in `NON_STATIC_OPS` and possibly `INTERPRETER_DISALLOWED_OPS`.
- However, EIP-3074 was ultimately not included in Pectra in favor of EIP-7702, so AUTH/AUTHCALL are not active on mainnet.

**Impact:** Currently none on mainnet Ethereum. Could become relevant if deployed to chains with non-standard opcode activations.

**Recommendation:** Monitor future hard forks and update the file as new opcodes are activated. The NatSpec already scopes the file to Cancun, which is accurate.

### A01-5: Bitmap completeness -- all opcodes in each category are accounted for [INFO]

**Location:** Lines 189-245

**Description:** Verified that each bitmap contains exactly the opcodes it should:
- **HALTING_BITMAP:** 6 opcodes (STOP, RETURN, REVERT, INVALID, SELFDESTRUCT, JUMP). No missing halting opcodes.
- **METAMORPHIC_OPS:** 5 opcodes (SELFDESTRUCT, DELEGATECALL, CALLCODE, CREATE, CREATE2). No missing metamorphic risk opcodes.
- **NON_STATIC_OPS:** 11 opcodes. Complete per EIP-214 + EIP-1153.
- **INTERPRETER_DISALLOWED_OPS:** 15 opcodes. Superset of NON_STATIC_OPS with 4 additional restrictions.

No opcodes are incorrectly included or excluded.

### A01-6: Shift expression arithmetic safety [INFO]

**Location:** Lines 189-245

**Description:** All shift expressions are of the form `(1 << uint256(EVM_OP_X))` where the shift amount is a compile-time constant in the range [0, 255]. Since `uint256` has 256 bits, shifting `1` left by at most 255 is always safe and produces the expected single-bit value. There is no possibility of:
- Shift overflow (would require shift >= 256)
- Incorrect bit positions (all opcode values verified correct above)
- Arithmetic underflow or overflow in the OR combinations

**Impact:** None. All arithmetic is provably safe.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| A01-1 | INFO | Inconsistent uint256 cast in HALTING_BITMAP shift expressions |
| A01-2 | INFO | DIFFICULTY name does not reflect post-Merge PREVRANDAO alias |
| A01-3 | INFO | NON_STATIC_OPS conservatively over-approximates CALL restriction |
| A01-4 | INFO | No coverage of post-Cancun opcodes |
| A01-5 | INFO | All bitmap memberships verified complete and correct |
| A01-6 | INFO | All shift arithmetic verified safe |

**No CRITICAL, HIGH, MEDIUM, or LOW findings.**

All 135 opcode constant values are correct per the EVM specification. All 4 derived bitmaps contain exactly the correct set of opcodes for their documented purpose. All shift expressions are arithmically safe. The file is well-structured with comprehensive NatSpec documentation. The existing test suite (`EVMOpcodes.t.sol`) provides independent verification of opcode values, bitmap construction, popcount, and individual bit membership, further increasing confidence in correctness.
