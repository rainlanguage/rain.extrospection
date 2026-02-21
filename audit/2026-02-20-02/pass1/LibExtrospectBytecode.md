# Security Audit: LibExtrospectBytecode.sol

**Auditor:** A02
**Date:** 2026-02-20
**File:** `src/lib/LibExtrospectBytecode.sol` (241 lines)

---

## Evidence of Thorough Reading

### Library Name

`LibExtrospectBytecode` (line 12), within `library LibExtrospectBytecode`.

### Functions (name and line number)

| Function | Line | Visibility | Mutability |
|---|---|---|---|
| `isEOFBytecode(bytes memory)` | 34 | internal | pure |
| `checkNotEOFBytecode(bytes memory)` | 46 | internal | pure |
| `tryTrimSolidityCBORMetadata(bytes memory)` | 96 | internal | pure |
| `checkCBORTrimmedBytecodeHash(address, bytes32)` | 123 | internal | view |
| `checkNoSolidityCBORMetadata(address)` | 142 | internal | view |
| `scanEVMOpcodesReachableInBytecode(bytes memory)` | 165 | internal | pure |
| `scanEVMOpcodesPresentInBytecode(bytes memory)` | 218 | internal | pure |

### Types, Errors, and Constants

**Errors (4):**
- `MetadataNotTrimmed()` (line 16)
- `EOFBytecodeNotSupported()` (line 19)
- `BytecodeHashMismatch(bytes32 expected, bytes32 actual)` (line 24)
- `UnexpectedMetadata()` (line 29)

**Imported types and constants:**
- `LibBytes`, `Pointer` from `rain.solmem/lib/LibBytes.sol` (line 5)
- `EVM_OP_JUMPDEST`, `HALTING_BITMAP` from `./EVMOpcodes.sol` (line 6)
- `using LibBytes for bytes` (line 13)

**No locally-defined constants, structs, or enums.**

---

## Security Findings

### A02-1: Opcode scan reads beyond bytecode allocation boundary when PUSH* is the final opcode(s) [LOW]

**Location:** Lines 176-184 (`scanEVMOpcodesReachableInBytecode`), Lines 225-236 (`scanEVMOpcodesPresentInBytecode`)

**Description:**

When a PUSH* opcode appears near the end of bytecode such that its declared inline data extends beyond the actual bytecode length, the cursor is advanced past `end`. On the next loop iteration, the `lt(cursor, end)` check terminates the loop, so no further opcodes are processed. However, the `mload(cursor)` that already executed for the PUSH* opcode itself read 32 bytes starting at `cursor`, which could extend into memory beyond the bytecode allocation.

Specifically, consider `scanEVMOpcodesPresentInBytecode` with bytecode `hex"7f"` (PUSH32, 1 byte, no data). At line 228, `mload(cursor)` reads 32 bytes. The cursor is positioned at the last byte of the bytecode data. The `mload` reads 31 bytes past the bytecode data. These bytes fall into whatever comes after the bytecode in memory. However, only `and(mload(cursor), 0xFF)` extracts the single byte at the cursor position (the opcode itself), so the read-past does not affect the result. The cursor is then advanced by 33 bytes past end, and the loop terminates.

This is a standard pattern in Solidity assembly (mload always reads 32 bytes regardless of remaining data). Since Solidity's memory model guarantees bytes after an allocation are either zeroed or belong to other allocations, and since the code only uses `and(..., 0xFF)` to extract the byte at the cursor position, the over-read does not produce incorrect results or corrupt data.

**Impact:** No functional impact. The over-read is benign because only the byte at the exact cursor position is extracted. The cursor overshooting past `end` is correctly handled by the `lt(cursor, end)` loop guard.

**Recommendation:** This is documented and tested behavior (tests `testScanEVMOpcodesReachableTruncatedPush1`, `testScanEVMOpcodesReachableTruncatedPush32`, etc.). No change needed. The behavior matches the reference implementation in `LibExtrospectionSlow`, which also advances `i` past the array boundary and terminates via the `i < data.length` check.

---

### A02-2: `tryTrimSolidityCBORMetadata` uses scratch space (memory 0x00-0x3F) for hash construction [INFO]

**Location:** Lines 106-114

**Description:**

The function writes to memory addresses `0x00` and `0x20` (Solidity scratch space) and then calls `keccak256(0, 0x40)` to hash 64 bytes. The assembly block is annotated `"memory-safe"`.

Per Solidity documentation, the scratch space at 0x00-0x3F is available for short-term use between assembly statements, and using it is compatible with the `memory-safe` annotation. The function does not allocate new memory and does not modify the free memory pointer.

After the `keccak256` call, the scratch space contains the masked data. Since no Solidity-level code reads scratch space expecting specific values after this assembly block (the only return value is `didTrim` which is set within assembly and `relevantHash` which is also set within assembly), this is safe.

**Impact:** None. This is correct usage of scratch space.

**Recommendation:** None.

---

### A02-3: `tryTrimSolidityCBORMetadata` in-place mutation of bytecode length only, not content [INFO]

**Location:** Line 113: `if didTrim { mstore(bytecode, sub(length, 53)) }`

**Description:**

When metadata is detected and trimmed, the function only modifies the `length` field of the `bytes memory` object by overwriting the first 32 bytes (the length prefix). The actual 53 bytes of metadata remain in memory, they are simply no longer addressable through the `bytes` type because the length has been reduced.

This is documented behavior (line 77: "NOTE bytecode is mutated in place"). The trimmed bytes are effectively inaccessible through normal Solidity `bytes` operations, `keccak256(bytecode)` will only hash `length - 53` bytes, and `.length` will return the reduced value.

**Impact:** None in terms of correctness. The "ghost" bytes remain in memory but are not reachable through the `bytes` reference. If a caller preserves a raw memory pointer to the metadata region, they could still read it, but this is not a realistic concern in the library's usage context.

**Recommendation:** The documentation on line 77 is sufficient. No change needed.

---

### A02-4: CBOR metadata trimming only supports the default Solidity metadata structure [INFO]

**Location:** Lines 52-116

**Description:**

The function is explicitly documented as an 80/20 approach (lines 72-91). It only detects and trims the default Solidity CBOR metadata structure (53 bytes: 2-entry CBOR map with IPFS hash and solc version, plus 2-byte length suffix). It will not trim:

- Metadata with `bzzr1` (Swarm) instead of `ipfs`
- Metadata with experimental features flag
- Metadata with only one entry
- Non-standard CBOR encodings

This is explicitly acknowledged in the NatSpec. The function returns `false` (does not revert) when metadata does not match the expected structure, which is the correct behavior.

**Impact:** False negatives (failure to trim valid but non-standard metadata) are possible but documented as expected.

**Recommendation:** None. The documentation is thorough.

---

### A02-5: `isEOFBytecode` loads 2 bytes using `mload` at offset 2 from bytecode start [INFO]

**Location:** Lines 36-39

**Description:**

```solidity
let firstTwoBytes := and(mload(add(bytecode, 2)), 0xFFFF)
isEOF := eq(firstTwoBytes, 0xEF00)
```

The function loads a full 32-byte word at `bytecode + 2`. The memory layout of `bytes memory` is: `[bytecode]` points to the length word (32 bytes), followed by data. So `bytecode + 2` reads 2 bytes of the length prefix (the lower 2 bytes) followed by 30 bytes of bytecode data. After `and(..., 0xFFFF)`, only the lowest 2 bytes of the 32-byte word are retained.

For this to equal `0xEF00`, we need the lowest 2 bytes of `mload(bytecode + 2)` to be `0xEF00`. Let's trace through:

- `mload(bytecode + 2)` reads bytes at memory positions `bytecode+2` through `bytecode+33`
- The length field occupies `bytecode+0` through `bytecode+31`
- Bytecode data starts at `bytecode+32`
- So `mload(bytecode+2)` returns a 32-byte word where:
  - Bytes 0-29 are from the length field (positions 2-31, all zeros for reasonable lengths)
  - Bytes 30-31 are the first two bytes of the bytecode data

Wait, let me recount. `mload(bytecode + 2)` reads 32 bytes starting at address `bytecode + 2`. The length field is at addresses `[bytecode, bytecode+31]`. The data starts at `bytecode+32`.

So `mload(bytecode+2)` reads addresses `[bytecode+2, bytecode+33]`:
- Addresses `bytecode+2` through `bytecode+31` (30 bytes) are the length field bytes 2..31
- Addresses `bytecode+32` through `bytecode+33` (2 bytes) are the first 2 bytes of data

The result of `mload` places these in big-endian order: the 30 length bytes are the high bytes, and the 2 data bytes are the low bytes. After `and(..., 0xFFFF)`, only the low 2 bytes (the first 2 bytes of data) remain.

For `bytecode.length >= 2` (checked at line 35), the data bytes exist. The first two bytes of EOF bytecode are `0xEF, 0x00`. In the mload result, these appear as: byte at `bytecode+32` = `0xEF` (bit position 8..15 of the low 16 bits), byte at `bytecode+33` = `0x00` (bit position 0..7). So the low 16 bits are `0xEF00`. This correctly matches.

**Impact:** Correct. The function properly detects EOF bytecode.

**Recommendation:** None.

---

### A02-6: Cursor initialization pattern `sub(cursor, 0x20)` relies on `dataPointer` returning `bytecode + 0x20` [INFO]

**Location:** Lines 173, 223

**Description:**

Both scan functions use the pattern:
```solidity
Pointer cursor = bytecode.dataPointer();
// ...
assembly ("memory-safe") {
    cursor := sub(cursor, 0x20)
    // ...
    for {} lt(cursor, end) {} {
        cursor := add(cursor, 1)
        let op := and(mload(cursor), 0xFF)
```

`dataPointer()` returns `bytecode + 0x20` (i.e., a pointer to the first data byte). The code then subtracts 0x20 to get back to `bytecode` (the length word). Then in the loop, `cursor` is first incremented by 1, making it `bytecode + 1`. `mload(bytecode + 1)` loads 32 bytes starting at the second byte of the length field. `and(..., 0xFF)` extracts only the lowest byte, which is the byte at position `bytecode + 32` — the first data byte.

This works because the length field is 32 bytes, and `mload` at offset 1 from the length word yields 31 bytes of length + 1 byte of data, with `and(_, 0xFF)` selecting only that last data byte. For the Nth iteration, `cursor = bytecode + N`, and `and(mload(bytecode + N), 0xFF)` yields `bytecode[32 + N - 1]` = the Nth data byte (0-indexed: N-1th byte).

For the loop guard: `end := add(cursor_initial, length)` where `cursor_initial = bytecode`. Actually, let me re-read:
```
cursor := sub(cursor, 0x20)   // cursor = bytecode + 0x20 - 0x20 = bytecode
end := add(cursor, length)     // end = bytecode + length
```
The loop condition is `lt(cursor, end)`, i.e., `cursor < bytecode + length`. The cursor starts at `bytecode`, is incremented to `bytecode + 1` before the first mload, and the last valid iteration is when `cursor = bytecode + length - 1` (before increment to `bytecode + length`). After increment to `bytecode + length`, `mload` extracts the byte at `bytecode + length + 31` = `bytecode + 32 + length - 1`, which is the last data byte. This is correct.

Wait, let me re-check. After the PUSH skip, cursor could become `bytecode + length` or greater, and on the next loop check `lt(cursor, end)` would be false (since `end = bytecode + length`), terminating the loop. So the last read is always in-bounds for the opcode itself.

**Impact:** Correct. The pointer arithmetic is sound.

**Recommendation:** None.

---

### A02-7: Reachable scan records PUSH* opcodes in the bitmap even when their data extends past bytecode end [INFO]

**Location:** Lines 182-189

**Description:**

When a PUSH* opcode is encountered, the opcode itself is recorded in the bitmap at line 189 (`bytesReachable := or(bytesReachable, shl(op, 1))`), and then the cursor is advanced past the inline data. If the inline data would extend past the end of the bytecode (truncated PUSH), the opcode is still recorded but the data bytes do not exist in the bytecode. This means truncated PUSH opcodes appear in the scan result.

This matches the reference implementation behavior exactly: the slow version at line 27-28 of `LibExtrospectionSlow.sol` first records `op`, then advances `i`. The fuzz test `testScanEVMOpcodesReachableReference` confirms equivalence.

For the reachable scan specifically: the PUSH opcodes (0x60-0x7F) are not in the `HALTING_BITMAP`, so they do not trigger halting. A truncated PUSH at bytecode end is recorded and then the loop terminates.

**Impact:** Correct and consistent. Truncated PUSH opcodes at the end of bytecode are treated as present/reachable. This is the expected behavior for malformed bytecode analysis.

**Recommendation:** None.

---

### A02-8: `tryTrimSolidityCBORMetadata` expected hash is a hardcoded constant without derivation visible in source [LOW]

**Location:** Line 104

**Description:**

```solidity
bytes32 expectedHash = bytes32(uint256(0x0e55864b80a56accebaca64500e23598f6acfb743a5475323f0b7f2d0d268c62));
```

This hash represents the `keccak256` of the masked CBOR metadata structure bytes. The masks at lines 101-103 zero out the variable portions (IPFS hash and solc version), and the expected hash is the keccak256 of the resulting constant bytes.

The hash value is not derived inline or documented with its preimage. A reader must reconstruct it manually by:
1. Taking the 53-byte default CBOR structure
2. Splitting into two 32-byte chunks (overlapping the last 53 bytes of bytecode)
3. Applying `maskA` and `maskB`
4. Hashing the result

The test `testTryTrimSolidityCBORMetadataContrived` (fuzz test) and `testTryTrimSolidityCBORMetdataBytecodeReal` (concrete test with known bytecode) verify the hash is correct. The contrived fuzz test constructs arbitrary bytecode, appends valid metadata, and confirms trimming works, which indirectly validates the hash.

**Impact:** Low. If the hash were wrong, the fuzz test would fail. The risk is maintainability: if the CBOR metadata format changes, the hash must be recalculated. A comment documenting the preimage or derivation method would aid future maintainers.

**Recommendation:** Consider adding a comment or test that explicitly shows the preimage computation, e.g., the masked constant bytes whose keccak256 equals this value.

---

### A02-9: `tryTrimSolidityCBORMetadata` metadata read uses `mload` at negative-indexed offsets from the end, which is correct but subtle [INFO]

**Location:** Lines 108-110

**Description:**

```solidity
let end := add(bytecode, length)
mstore(0, and(maskA, mload(sub(end, 0x20))))
mstore(0x20, and(maskB, mload(end)))
```

- `end = bytecode + length` (not `bytecode + 0x20 + length`). This is the memory address of the last byte of the length prefix + length bytes of data. Actually: `bytecode` is the address of the length word. `bytecode + length` for a bytecode of length L points to `bytecode + L`, which is `L - 32` bytes into the data region (since data starts at `bytecode + 32`). This seems wrong at first glance.

Let me trace more carefully. `bytecode` is a `bytes memory` pointer. In Solidity memory layout:
- `bytecode` points to the length (32 bytes)
- `bytecode + 32` is the first data byte

`length = bytecode.length` which is the number of data bytes.

`end = add(bytecode, length)` = `bytecode + length`.

For bytecode of length 53: `end = bytecode + 53`. The data occupies `bytecode + 32` through `bytecode + 32 + 52 = bytecode + 84`.

`mload(end)` = `mload(bytecode + 53)` reads 32 bytes at `[bytecode + 53, bytecode + 84]`. That is `[data[21], data[22], ..., data[52]]` — the last 32 bytes of the 53-byte data. This is correct: it reads the last 32 bytes of the bytecode.

`mload(sub(end, 0x20))` = `mload(bytecode + 53 - 32)` = `mload(bytecode + 21)` reads 32 bytes at `[bytecode + 21, bytecode + 52]`. That is 11 bytes of the length prefix (bytes 21-31, all zero for lengths < 2^(8*11)) and then `data[0]` through `data[20]` — the first 21 bytes of the bytecode data. This is the 32 bytes ending 0x20 bytes before the last byte.

Wait, the metadata is the LAST 53 bytes. For a bytecode of length L >= 53, the metadata is at `data[L-53]` through `data[L-1]`.

`mload(end)` = `mload(bytecode + L)` reads `[bytecode + L, bytecode + L + 31]` = `[data[L-32], ..., data[L-1]]` — the last 32 bytes. This is the last 32 bytes of the metadata, which is correct.

`mload(sub(end, 0x20))` = `mload(bytecode + L - 32)` reads `[bytecode + L - 32, bytecode + L - 1]` = `[data[L-64], ..., data[L-33]]`. Hmm, that's 32 bytes starting 64 bytes before the end of data and ending 33 bytes before the end.

Actually: for L = 53, `mload(bytecode + 53 - 32)` = `mload(bytecode + 21)`. Memory addresses `bytecode + 21` through `bytecode + 52`. The length prefix occupies `bytecode + 0` through `bytecode + 31`. Data starts at `bytecode + 32`. So this read includes length-prefix bytes 21-31 (11 bytes of zeros) and data bytes 0-20 (21 bytes). With `maskA` applied, the zeros from the length prefix are masked to zero, and only the relevant metadata bytes from data[0..20] survive.

For larger L, say L = 100, metadata is at data[47..99]. `mload(bytecode + 100 - 32)` = `mload(bytecode + 68)` reads data[36..67]. This is NOT the first part of the metadata (which starts at data[47]). Something seems off.

Let me reconsider. The metadata is the last 53 bytes. We need to read the last 53 bytes. The code reads two 32-byte words: one at `end - 0x20` and one at `end`. Together these cover 64 bytes: the last 64 bytes of `[bytecode_start, bytecode_start + length + 32)`, or equivalently, the last 64 bytes of the raw memory block. The metadata (53 bytes) fits within these 64 bytes. The masks zero out the non-metadata portions (the 11 extra bytes at the beginning of the first word, which are pre-metadata data or length-field remnants) as well as the variable IPFS hash and solc version within the metadata.

Wait, I need to re-examine the masks. `maskA` has 8 non-zero bytes (0xFF) at the high end and 13 zero bytes (0x00) at the low end. That means the first 32-byte word, after masking, retains bytes 0-7 (the top 8 bytes of the 32-byte word) and zeros out bytes 8-31 (24 bytes). But `maskA = 0xFFFFFFFFFFFFFFFF00000000000000000000000000` which is:
```
FF FF FF FF FF FF FF FF 00 00 00 00 00 00 00 00 00 00 00 00 00
```
That is 21 bytes. But uint256 is 32 bytes. Let me recount:
`0xFFFFFFFFFFFFFFFF00000000000000000000000000` — this is 21 bytes expressed as hex, which means as a uint256 it is padded with leading zeros to 32 bytes:
```
00 00 00 00 00 00 00 00 00 00 00 FF FF FF FF FF FF FF FF 00 00 00 00 00 00 00 00 00 00 00 00 00
```
Wait, that's 31 bytes. Let me count the hex digits: `FFFFFFFFFFFFFFFF00000000000000000000000000` = 42 hex digits = 21 bytes. So as a uint256: `0x0000000000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000` (32 bytes).

Hmm, that does not look right either. Let me just count directly:
- `maskA`: `0xFFFFFFFFFFFFFFFF00000000000000000000000000` = 8 bytes of 0xFF followed by 13 bytes of 0x00 = 21 bytes total. As uint256, the high 11 bytes are implicitly 0. So the 32-byte representation is: `00*11 FF*8 00*13`.
- `maskB`: `0x000000000000000000000000000000000000000000FFFFFFFFFFFF000000FFFF` = 21 bytes of 0x00, then 6 bytes of 0xFF, then 3 bytes of 0x00, then 2 bytes of 0xFF = 32 bytes total.

The metadata structure (53 bytes) overlaps these two 32-byte reads. The first read captures the first 32 bytes that overlap with the metadata region, and the second captures the last 32 bytes. Since 32 + 32 = 64 and the metadata is 53 bytes, there is an 11-byte overlap, and the first read includes 11 bytes before the metadata.

The masks zero out:
- In the first word: the 11 leading bytes (before metadata) and the 13 trailing bytes (which are the IPFS hash, a variable part)
- In the second word: the 21 leading bytes (which overlap the first word's data), leaving 6 bytes of fixed CBOR structure, 3 zero bytes (solc version, variable), and 2 bytes of length suffix

This mask pattern correctly isolates only the fixed CBOR structure bytes while zeroing the variable IPFS hash and solc version. The keccak256 of this masked data is then compared to the precomputed expected hash.

**Impact:** Correct. The pointer arithmetic and masking logic are sound. The use of two overlapping 32-byte reads to capture 53 bytes is an efficient pattern.

**Recommendation:** None. The approach is valid.

---

### A02-10: `scanEVMOpcodesReachableInBytecode` over-approximation of reachability does not account for conditional JUMPI [INFO]

**Location:** Lines 150-208

**Description:**

The function uses a linear scan that treats `JUMP` (unconditional) as halting but does NOT treat `JUMPI` (0x57, conditional jump) as halting. This is correct: `JUMPI` can fall through if the condition is false, so treating it as halting would miss fall-through opcodes.

However, the scan is an over-approximation in general because:
1. Not all JUMPDESTs are reachable at runtime
2. The linear scan cannot determine which JUMPDESTs are actual targets of JUMP/JUMPI instructions
3. Dead code between a JUMPDEST that is never targeted and the next halt will be incorrectly counted as reachable

This is documented in the NatSpec (lines 157-158: "This is an over-approximation because not all JUMPDESTs are actually reachable at runtime.").

**Impact:** By design. The over-approximation is conservative: it may report opcodes as reachable when they are actually dead code, but it will never miss truly reachable opcodes. For security scanning (metamorphic detection), false positives (over-reporting) are safer than false negatives (under-reporting).

**Recommendation:** None. This is a deliberate design choice that favors safety.

---

### A02-11: `memory-safe` annotation correctness across all assembly blocks [INFO]

**Location:** Lines 36, 106, 172, 222

**Description:**

The Solidity compiler uses the `memory-safe` annotation to enable certain optimizations. An assembly block is memory-safe if it only accesses memory that was allocated by Solidity, or uses the scratch space (0x00-0x3F), or uses memory past the free memory pointer for temporary reads.

Analysis of each block:

1. **Line 36** (`isEOFBytecode`): Reads `mload(add(bytecode, 2))` which reads within the bytecode allocation. No writes. **Memory-safe: YES.**

2. **Line 106** (`tryTrimSolidityCBORMetadata`): Writes to scratch space at 0x00 and 0x20. Reads from the bytecode allocation. Writes the bytecode length at `mstore(bytecode, ...)`. The bytecode memory was passed by the caller and the write to its length field is a mutation of existing allocated memory. `keccak256(0, 0x40)` reads scratch space. **Memory-safe: YES.**

3. **Line 172** (`scanEVMOpcodesReachableInBytecode`): Reads from bytecode via `mload(cursor)`. No memory writes (only writes to stack variables `bytesReachable`, `halted`, `op`, etc.). **Memory-safe: YES.**

4. **Line 222** (`scanEVMOpcodesPresentInBytecode`): Reads from bytecode via `mload(cursor)`. No memory writes. **Memory-safe: YES.**

**Impact:** All `memory-safe` annotations are accurate.

**Recommendation:** None.

---

### A02-12: `checkCBORTrimmedBytecodeHash` copies entire bytecode into memory before trimming [INFO]

**Location:** Lines 123-133

**Description:**

```solidity
bytes memory bytecode = account.code;
```

This copies the entire runtime bytecode of `account` into memory. For large contracts (up to the 24KB limit), this allocates significant memory. The function then trims metadata in-place and hashes the result. This is gas-intensive but documented in CLAUDE.md as intentional ("the algorithms are gas-intensive and primarily intended for offchain use").

**Impact:** High gas cost for onchain use. No security issue.

**Recommendation:** None. The intended use case is offchain.

---

### A02-13: No protection against address(0) or EOA in `checkCBORTrimmedBytecodeHash` and `checkNoSolidityCBORMetadata` [INFO]

**Location:** Lines 123, 142

**Description:**

If `account` has no code (EOA or precompile), `account.code` returns an empty `bytes` array. In `checkCBORTrimmedBytecodeHash`, the flow would be:
1. `bytecode.length == 0`
2. `tryTrimSolidityCBORMetadata` returns `false` (length < 53)
3. Reverts with `MetadataNotTrimmed()`

In `checkNoSolidityCBORMetadata`:
1. `bytecode.length == 0`
2. `tryTrimSolidityCBORMetadata` returns `false`
3. No revert (the function only reverts if metadata IS detected)

The EOA case in `checkNoSolidityCBORMetadata` does not revert, which may be unexpected if the caller assumes the account has code. However, the function's purpose is specifically to check for the absence of metadata, and an account with no code trivially has no metadata.

**Impact:** Informational. Both functions behave reasonably for EOA/empty-code inputs. `checkCBORTrimmedBytecodeHash` correctly fails on EOAs. `checkNoSolidityCBORMetadata` silently passes for EOAs, which could be surprising but is logically correct.

**Recommendation:** Consider documenting the behavior for accounts with no code, or adding a minimum length check if the caller should only pass contracts.

---

### A02-14: PUSH data skipping arithmetic is correct for the full PUSH1-PUSH32 range [INFO]

**Location:** Lines 182-185 (reachable scan), Lines 235-236 (present scan)

**Description:**

```solidity
let push := sub(op, 0x60)
if lt(push, 0x20) {
    cursor := add(cursor, add(push, 1))
}
```

For op = 0x60 (PUSH1): `push = 0`, skip = 1 byte. Correct (PUSH1 has 1 byte of data).
For op = 0x7F (PUSH32): `push = 0x1F = 31`, skip = 32 bytes. Correct (PUSH32 has 32 bytes of data).
For op = 0x5F (PUSH0): `push = sub(0x5F, 0x60)` = underflow to `0xFFFF...FFFF`. `lt(0xFFFF...FFFF, 0x20)` = false. No skip. Correct (PUSH0 has no inline data).
For op < 0x60 (non-PUSH): `push` underflows, `lt(huge_number, 0x20)` = false. No skip. Correct.
For op > 0x7F (post-PUSH range): `push >= 0x20`, `lt(push, 0x20)` = false. No skip. Correct.

The arithmetic correctly handles the full opcode range including the PUSH0 boundary, unsigned underflow for opcodes below 0x60, and the upper boundary at 0x80+.

**Impact:** Correct.

**Recommendation:** None.

---

### A02-15: Halting bitmap check uses `and(shl(op, 1), haltingMask)` — shift direction is correct [INFO]

**Location:** Lines 189, 192

**Description:**

```solidity
bytesReachable := or(bytesReachable, shl(op, 1))
if and(shl(op, 1), haltingMask) { halted := 1 }
```

`shl(op, 1)` shifts the value `1` left by `op` bits, producing `1 << op`. This sets bit `op` in the bitmap. For `op = 0x00` (STOP), this sets bit 0. For `op = 0xFF` (SELFDESTRUCT), this sets bit 255. This matches the bitmap convention documented in CLAUDE.md ("bit N represents opcode 0xN").

The `and(shl(op, 1), haltingMask)` check tests whether the opcode is in the halting set. The HALTING_BITMAP constant from EVMOpcodes.sol is `(1 << 0x00) | (1 << 0xF3) | (1 << 0xFD) | (1 << 0xFE) | (1 << 0xFF) | (1 << 0x56)` = STOP | RETURN | REVERT | INVALID | SELFDESTRUCT | JUMP.

**Impact:** Correct. The shift direction and bitmap semantics are consistent.

**Recommendation:** None.

---

### A02-16: `isEOFBytecode` returns false for 0-byte and 1-byte inputs without entering assembly [INFO]

**Location:** Lines 34-41

**Description:**

The `if (bytecode.length >= 2)` guard on line 35 ensures that:
- Empty bytecode (`length == 0`): returns `false` (default `isEOF` value)
- Single byte `0xEF` (`length == 1`): returns `false`
- Only bytecodes of length >= 2 are checked

The function does not check for `0xEF01` or other `0xEFxx` prefixes that are not EOF. Only `0xEF00` is treated as EOF, which aligns with EIP-3541 and EIP-7692.

**Impact:** Correct.

**Recommendation:** None.

---

## Summary

| ID | Severity | Title |
|---|---|---|
| A02-1 | LOW | PUSH* scan reads beyond bytecode when truncated at end |
| A02-2 | INFO | `tryTrimSolidityCBORMetadata` scratch space usage is correct |
| A02-3 | INFO | In-place mutation modifies length only |
| A02-4 | INFO | CBOR trimming only supports default Solidity metadata |
| A02-5 | INFO | `isEOFBytecode` mload offset arithmetic is correct |
| A02-6 | INFO | Cursor initialization pattern is correct |
| A02-7 | INFO | Truncated PUSH opcodes are recorded in bitmap |
| A02-8 | LOW | Expected hash is hardcoded without inline derivation |
| A02-9 | INFO | Metadata read pointer arithmetic is correct |
| A02-10 | INFO | Reachable scan over-approximation is by design |
| A02-11 | INFO | All `memory-safe` annotations are accurate |
| A02-12 | INFO | Full bytecode copy is gas-intensive but intended for offchain |
| A02-13 | INFO | EOA/empty-code behavior in check functions |
| A02-14 | INFO | PUSH data skipping arithmetic is correct for full range |
| A02-15 | INFO | Halting bitmap shift direction is correct |
| A02-16 | INFO | EOF detection returns false for short inputs |

**No CRITICAL or HIGH severity issues found.**

The library demonstrates careful implementation with correct memory handling in all assembly blocks, proper PUSH* opcode data skipping, sound halting logic, and accurate `memory-safe` annotations. The CBOR metadata trimming uses an efficient masked-hash approach that is validated by both concrete and fuzz tests. The fuzz tests comparing against reference implementations provide strong assurance of correctness across the opcode scanning functions.
