# Audit: LibExtrospectBytecode.sol

**Auditor:** A07
**Date:** 2026-02-20
**File:** `src/lib/LibExtrospectBytecode.sol`

---

## Evidence of Thorough Reading

### Library Name

`LibExtrospectBytecode` (line 12)

### Every Function with Line Number

| Function | Line | Visibility |
|----------|------|------------|
| `isEOFBytecode(bytes memory bytecode)` | 34 | internal pure |
| `checkNotEOFBytecode(bytes memory bytecode)` | 46 | internal pure |
| `tryTrimSolidityCBORMetadata(bytes memory bytecode)` | 96 | internal pure |
| `checkCBORTrimmedBytecodeHash(address account, bytes32 expected)` | 123 | internal view |
| `checkNoSolidityCBORMetadata(address account)` | 142 | internal view |
| `scanEVMOpcodesReachableInBytecode(bytes memory bytecode)` | 156 | internal pure |
| `scanEVMOpcodesPresentInBytecode(bytes memory bytecode)` | 209 | internal pure |

### Every Custom Error

| Error | Line | Parameters |
|-------|------|------------|
| `MetadataNotTrimmed()` | 16 | none |
| `EOFBytecodeNotSupported()` | 19 | none |
| `BytecodeHashMismatch(bytes32 expected, bytes32 actual)` | 24 | expected, actual |
| `UnexpectedMetadata()` | 29 | none |

### Constants

No constants are defined in this file. Imports used:
- `EVM_OP_JUMPDEST` from `./EVMOpcodes.sol` (line 6)
- `HALTING_BITMAP` from `./EVMOpcodes.sol` (line 6)

### Using Declarations

- `using LibBytes for bytes;` (line 13)

### Assembly Blocks

- `isEOFBytecode`: lines 36-40 (`memory-safe`)
- `tryTrimSolidityCBORMetadata`: lines 106-114 (`memory-safe`)
- `scanEVMOpcodesReachableInBytecode`: lines 163-199 (`memory-safe`)
- `scanEVMOpcodesPresentInBytecode`: lines 213-229 (`memory-safe`)

### Key Constants in `tryTrimSolidityCBORMetadata`

- `maskA = 0xFFFFFFFFFFFFFFFF00000000000000000000000000` (line 101)
- `maskB = 0x000000000000000000000000000000000000000000FFFFFFFFFFFF000000FFFF` (line 103)
- `expectedHash = 0x0e55864b80a56accebaca64500e23598f6acfb743a5475323f0b7f2d0d268c62` (line 104)

---

## Detailed Analysis

### 1. `isEOFBytecode` (lines 34-41)

**Bytecode pointer layout:** `bytecode` points to the 32-byte ABI length word; data begins at `bytecode + 0x20`.

**Assembly reads:** `mload(add(bytecode, 2))` loads 32 bytes at `[bytecode+2 .. bytecode+33]`. The `and(..., 0xFFFF)` mask keeps the lowest two bytes, which are at `bytecode+32` = `data[0]` and `bytecode+33` = `data[1]`.

**Bounds:** For `length >= 2`, `data[1]` is at `bytecode+33`. The allocated region for a 2-element `bytes` is at minimum `[bytecode .. bytecode+63]` (32 for length word + 2 data bytes + 30 padding). Address `bytecode+33` is within the allocated region. Safe.

**Logic:** `eq(firstTwoBytes, 0xEF00)` checks `data[0] == 0xEF && data[1] == 0x00`, matching the EIP-3540 EOF magic bytes. Correct.

**Empty and single-byte bytecode:** The `length >= 2` guard prevents the assembly block from executing when it would be unsafe. Returns false. Correct.

### 2. `checkNotEOFBytecode` (lines 46-50)

Thin wrapper around `isEOFBytecode`. Uses `EOFBytecodeNotSupported` custom error (no string messages). Correct.

### 3. `tryTrimSolidityCBORMetadata` (lines 96-116)

**CBOR structure verification (53 bytes total):**

```
[0]    0xa2          CBOR map header (2 entries)
[1]    0x64          CBOR text string prefix (4-byte string follows)
[2-5]  0x69706673    "ipfs" in ASCII/UTF-8
[6-7]  0x5822        CBOR byte string prefix (34-byte hash follows)
[8-41] <dynamic>     34-byte IPFS hash
[42]   0x64          CBOR text string prefix (4-byte string follows)
[43-46] 0x736f6c63   "solc" in ASCII/UTF-8
[47]   0x43          CBOR byte string prefix (3-byte version follows)
[48-50] <dynamic>    3-byte solc version
[51-52] 0x0033       metadata length (51 decimal)
```

Total: 1+1+4+2+34+1+4+1+3+2 = **53 bytes**. Consistent with the `length >= 53` guard and `sub(length, 53)` subtraction.

**Pointer arithmetic:**

Let `B` = `bytecode` (pointer to length word). Data begins at `B + 0x20 = B + 32`.
- `end = add(bytecode, length) = B + length`
- `mload(sub(end, 0x20)) = mload(B + length - 32)` reads bytes at `[B+length-32 .. B+length-1]`
  - In data-space terms: `data[length-64]` through `data[length-33]`
  - For `length = 53`: reads `data[-11]` (11 bytes from length word) through `data[20]` (= `metadata[0..20]`)
  - The 11 bytes from the length word are zeroed by `maskA`.
- `mload(end) = mload(B + length)` reads bytes at `[B+length .. B+length+31]`
  - In data-space terms: `data[length-32]` through `data[length-1]`
  - For `length = 53`: reads `data[21..52]` = `metadata[21..52]`
  - The last byte read is `B + length + 31 = B + 32 + length - 1`, exactly the last data byte. Safe for all `length >= 53`.

**Mask verification:**

`maskA` (as a 32-byte big-endian value) `= 0x0000000000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000`:
- Zeros bytes 0-10 (11 bytes of the length word that precede `data[0]`)
- Keeps bytes 11-18 = `metadata[0..7]` = `0xa2`, `0x64`, `ipfs`, `0x5822` (8 static bytes)
- Zeros bytes 19-31 = `metadata[8..20]` = start of IPFS hash (13 dynamic bytes)

`maskB` (as a 32-byte big-endian value) `= 0x000000000000000000000000000000000000000000FFFFFFFFFFFF000000FFFF`:
- Zeros bytes 0-20 = `metadata[21..41]` = remaining 21 bytes of IPFS hash (dynamic)
- Keeps bytes 21-26 = `metadata[42..47]` = `0x64`, `solc`, `0x43` (6 static bytes)
- Zeros bytes 27-29 = `metadata[48..50]` = solc version (3 dynamic bytes)
- Keeps bytes 30-31 = `metadata[51..52]` = `0x0033` length field (2 static bytes)

Total static bytes checked: 8 (from maskA) + 6 + 2 (from maskB) = **16 static bytes**, covering all structural CBOR fields while masking both dynamic fields (34-byte IPFS hash and 3-byte version).

**Scratch space usage:** Writing to `mstore(0, ...)` and `mstore(0x20, ...)` (addresses 0x00-0x3F) is permitted scratch space under the Solidity memory model, consistent with the `memory-safe` annotation.

**In-place mutation:** On a match, `mstore(bytecode, sub(length, 53))` reduces the ABI length word by 53. This is documented in the NatSpec. Both call sites (`checkCBORTrimmedBytecodeHash` and `checkNoSolidityCBORMetadata`) operate on fresh copies from `account.code`. No aliasing issue.

**Subtraction underflow:** `sub(length, 53)` cannot underflow because the `length >= 53` guard ensures `length` is at least 53. Safe.

**Documented false negatives:** Non-standard CBOR metadata (different structure, alternative keys, etc.) will not be detected. This is explicitly documented in the NatSpec as an intentional limitation of the 80/20 approach.

### 4. `checkCBORTrimmedBytecodeHash` (lines 123-133)

- Loads `account.code` into a fresh `bytes memory` buffer (lines 124).
- Calls `tryTrimSolidityCBORMetadata`; reverts with `MetadataNotTrimmed` if not detected.
- Computes `keccak256` of the trimmed bytes and compares to `expected`; reverts with `BytecodeHashMismatch` if different.

**Security property:** The hash check is performed over the bytecode *after* the standard metadata is stripped. Changing the IPFS hash or solc version in metadata (the dynamic fields) does not affect the check because those bytes are stripped. Changing the actual code logic would produce a different trimmed hash, causing the check to fail.

**Metamorphic resistance:** A metamorphic contract that selfdestructs and redeploys with different code would produce a different `keccak256` hash and fail the check. The check is sound against metamorphic substitution at the time of verification.

**Timing note (acknowledged, not a library bug):** Like all on-chain bytecode checks, there is a TOCTOU window if the check result is cached and relied upon across blocks. This is not a library defect.

### 5. `checkNoSolidityCBORMetadata` (lines 142-148)

Inverse logic: reverts with `UnexpectedMetadata` if standard CBOR *is* detected. Used when bytecode was compiled without CBOR metadata (e.g., `cbor_metadata = false`). A clean contract with no trailing standard-CBOR passes; a contract with standard CBOR fails. False negatives (non-standard metadata passing) are documented.

### 6. `scanEVMOpcodesReachableInBytecode` (lines 156-200)

**Cursor initialization:**
- `cursor = bytecode.dataPointer()` = `B + 0x20`
- `cursor := sub(cursor, 0x20)` → `cursor = B`
- `end := add(cursor, length)` → `end = B + length`

**Per-iteration read:**
- `cursor := add(cursor, 1)` → `cursor = B + k` (for `k` from 1 to `length`)
- `op := and(mload(cursor), 0xFF)` → `mload(B + k)` reads 32 bytes; the LSB (lowest byte) is at address `B + k + 31 = B + 32 + (k-1) = data[k-1]`
- Correctly reads `data[0]` through `data[length-1]`

**Loop termination:** Condition `lt(cursor, end)` is checked before the body increments `cursor`. Last entry when `cursor = B + length - 1` (reads `data[length-1]`); then `cursor = B + length = end`, loop exits. Correct.

**PUSH skip calculation:**
```
let push := sub(op, 0x60)
if lt(push, 0x20) { cursor := add(cursor, add(push, 1)) }
```
- `PUSH1` (0x60): `push = 0`, skip `1` byte. Correct (PUSH1 carries 1 data byte).
- `PUSH32` (0x7F): `push = 31`, skip `32` bytes. Correct (PUSH32 carries 32 data bytes).
- `PUSH0` (0x5F): `push = 0x5F - 0x60` underflows to `2^256 - 1` (not `< 0x20`). No skip. Correct (PUSH0 has no data bytes).
- Opcodes `>= 0x80`: `push >= 0x20`. No skip. Correct.
- Opcodes `< 0x60`: underflow, huge value, no skip. Correct.

**PUSH skip happens before the halted switch:** This is critical and correct. If a PUSH opcode appears in halted code, its data bytes (which may contain the value `0x5B` / JUMPDEST) are still skipped. This prevents false-positive JUMPDEST detection from PUSH data.

**Halted state logic:**
- `halted = 0` (running): record opcode in bitmap; if it is in `HALTING_BITMAP`, set `halted = 1`.
- `halted = 1` (halted): if opcode is `JUMPDEST` (0x5B), set `halted = 0` and record JUMPDEST; otherwise discard.
- `default { revert(0, 0) }`: unreachable guard. Correct.

**HALTING_BITMAP correctness (from EVMOpcodes.sol):**

| Opcode | Value | Included | Rationale |
|--------|-------|----------|-----------|
| STOP | 0x00 | Yes | Terminates execution |
| JUMP | 0x56 | Yes | Unconditional, no fall-through |
| JUMPI | 0x57 | No | Conditional, can fall-through |
| RETURN | 0xF3 | Yes | Terminates execution |
| REVERT | 0xFD | Yes | Terminates execution |
| INVALID | 0xFE | Yes | Terminates execution |
| SELFDESTRUCT | 0xFF | Yes | Terminates execution |

JUMPI (0x57) is correctly excluded. Including JUMP (0x56) but excluding JUMPI (0x57) is the correct distinction.

**Bit operations:** `shl(op, 1)` in Yul means `1 << op`, computing a single-bit mask for opcode `op`. The `//slither-disable-next-line incorrect-shift` annotations suppress a known Slither false positive arising from Yul vs. Solidity syntax differences.

**Linear over-approximation:** Every `JUMPDEST` in bytecode is treated as reachable, regardless of whether any `JUMP` actually targets it. This is a documented design choice (consistent with upstream reference) that errs on the side of over-reporting reachability, which is the safer direction for security purposes.

**Fuzz verification:** The function is fuzz-tested against `LibExtrospectionSlow.scanEVMOpcodesReachableInBytecodeSlow` across `2048` runs (per `testScanEVMOpcodesReachableReference`), providing strong equivalence assurance.

### 7. `scanEVMOpcodesPresentInBytecode` (lines 209-230)

Identical cursor arithmetic, bounds, and PUSH skip logic to the reachable scan, minus the halted state machine. Only difference: every non-skipped byte is recorded in the bitmap unconditionally.

Also fuzz-tested against `LibExtrospectionSlow.scanEVMOpcodesPresentInBytecodeSlow`.

### 8. Memory Safety Annotation Correctness

| Function | Writes outside stack | Reads outside stack | memory-safe correct? |
|----------|---------------------|---------------------|----------------------|
| `isEOFBytecode` | None | Reads from allocated bytecode data | Yes |
| `tryTrimSolidityCBORMetadata` | scratch space (0x00-0x3F), length word of bytecode | Reads from allocated bytecode data | Yes |
| `scanEVMOpcodesReachableInBytecode` | None (only stack) | Reads from allocated bytecode data | Yes |
| `scanEVMOpcodesPresentInBytecode` | None (only stack) | Reads from allocated bytecode data | Yes |

No function reads or writes beyond the bounds of its allocated memory regions.

---

## Findings

No security findings.

The library is correctly implemented across all audited areas:

1. **Memory safety:** All pointer arithmetic is verified correct and within allocated bounds for all inputs satisfying the documented preconditions. `memory-safe` annotations are accurate throughout.

2. **PUSH opcode width:** The `sub(op, 0x60)` / `lt(push, 0x20)` pattern correctly handles the full range from PUSH0 (no data) through PUSH1-PUSH32 (1-32 data bytes) and non-PUSH opcodes, relying on unsigned underflow semantics that are well-understood and correct.

3. **Halted scan logic:** PUSH data is skipped before the halted switch, preventing false-positive JUMPDEST detection from PUSH arguments. The HALTING_BITMAP correctly includes all terminal opcodes and excludes the conditional JUMPI.

4. **JUMPDEST tracking:** Only a byte encountered as a true opcode position (not as PUSH data) in halted state reactivates scanning. The interplay between PUSH skip and halted state is correct.

5. **CBOR trimming:** The two masks precisely cover all 16 static structural bytes while zeroing all dynamic bytes (34-byte IPFS hash, 3-byte solc version). The expected hash and masks are mutually consistent.

6. **EOF detection:** The `0xEF00` magic check correctly follows EIP-3540, with a safe length guard.

7. **Bytecode hash bypass:** Not possible. `keccak256` collision resistance ensures that different code cannot produce the same trimmed hash, and changing only the dynamic metadata fields does not affect the trimmed hash.

8. **In-place mutation:** Documented and confined to contexts where `account.code` provides a fresh buffer. No aliasing hazard in the current codebase.

9. **Documented limitations:** False negatives for non-standard CBOR metadata in `checkNoSolidityCBORMetadata` and `tryTrimSolidityCBORMetadata` are explicitly acknowledged in NatSpec. The linear over-approximation in `scanEVMOpcodesReachableInBytecode` (all JUMPDESTs treated as reachable) is an intentional, documented, safe-direction design choice.
