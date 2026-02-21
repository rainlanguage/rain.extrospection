# Audit: LibExtrospectBytecode.sol

**Auditor:** A06
**Date:** 2026-02-19
**File:** `src/lib/LibExtrospectBytecode.sol`

## Evidence of Thorough Reading

### Library Name

`LibExtrospectBytecode` (line 12), defined in `library LibExtrospectBytecode`.

### Functions

| Function | Line | Visibility |
|----------|------|------------|
| `isEOFBytecode(bytes memory)` | 29 | internal pure |
| `checkNotEOFBytecode(bytes memory)` | 41 | internal pure |
| `tryTrimSolidityCBORMetadata(bytes memory)` | 90 | internal pure |
| `checkCBORTrimmedBytecodeHash(address, bytes32)` | 117 | internal view |
| `scanEVMOpcodesReachableInBytecode(bytes memory)` | 135 | internal pure |
| `scanEVMOpcodesPresentInBytecode(bytes memory)` | 190 | internal pure |

### Errors

| Error | Line |
|-------|------|
| `MetadataNotTrimmed()` | 16 |
| `EOFBytecodeNotSupported()` | 19 |
| `BytecodeHashMismatch(bytes32 expected, bytes32 actual)` | 24 |

### Types and Constants

No custom types or constants are defined in this file. The library uses:
- `LibBytes` and `Pointer` imported from `rain.solmem/lib/LibBytes.sol` (line 5)
- `EVM_OP_JUMPDEST` and `HALTING_BITMAP` imported from `./EVMOpcodes.sol` (line 6)

### Using Declarations

- `using LibBytes for bytes;` (line 13)

---

## Security Review

### 1. Assembly Memory Safety

#### 1.1 `tryTrimSolidityCBORMetadata` (lines 90-110)

**Scratch space usage (lines 100-108):** The assembly block writes to memory offsets `0` and `0x20` (scratch space) and reads from the bytecode array. Per Solidity semantics, scratch space (`0x00`-`0x3F`) may be freely used within `memory-safe` assembly blocks. The function then conditionally mutates the bytecode length word via `mstore(bytecode, sub(length, 53))`.

**Pointer arithmetic verification:**
- `end := add(bytecode, length)` -- this points to `bytecode_base + length`, which is `0x20` bytes before the end of the bytecode data.
- `mload(sub(end, 0x20))` reads 32 bytes starting at `bytecode + length - 0x20`. When `length >= 53`, this reads a region that overlaps with the last 53 bytes of data.
- `mload(end)` reads 32 bytes starting at `bytecode + length`. The last byte read (`bytecode + length + 0x1F`) equals `bytecode + 0x20 + length - 1`, which is exactly the last data byte.

Both reads are within or immediately adjacent to the allocated bytecode array. The `mload` extends at most a few bytes past the allocated region into Solidity's padding area, which is safe in EVM memory.

**Minimum length (53):** With `length = 53`, the first `mload` reads from `bytecode + 21`, which crosses the boundary between the length word and the data. `maskA` correctly zeros out the 11 bytes belonging to the length word (positions 0-10 of the 32-byte word), keeping only the 21 bytes that are actual metadata data. Verified correct.

#### 1.2 `scanEVMOpcodesReachableInBytecode` (lines 135-179)

**Pointer arithmetic:**
- `cursor` is initialized to `bytecode.dataPointer()` (= `bytecode + 0x20`), then adjusted by `sub(cursor, 0x20)` making it equal to `bytecode` (the length word pointer).
- `end := add(cursor, length)` = `bytecode + length`.
- Each iteration: `cursor := add(cursor, 1)`, then `op := and(mload(cursor), 0xFF)`.
- `and(mload(cursor), 0xFF)` extracts the least significant byte of the 32-byte word loaded at `cursor`, which is the byte at address `cursor + 31`.
- For `cursor = bytecode + k` (k from 1 to length): the byte read is at `bytecode + k + 31 = bytecode + 0x20 + (k-1)` = `data[k-1]`.
- The loop runs for `k = 1` through `k = length` (since check is `lt(cursor, end)` before increment), reading `data[0]` through `data[length-1]`. Verified correct.

**No out-of-bounds writes:** The assembly only writes to stack variables (`cursor`, `end`, `op`, `push`, `halted`, `bytesReachable`). No memory writes. Memory-safe annotation is correct.

#### 1.3 `scanEVMOpcodesPresentInBytecode` (lines 190-211)

Identical pointer arithmetic pattern to the reachable scan. Same verification applies. Correct.

### 2. PUSH* Skip Logic

The PUSH1-PUSH32 opcodes (0x60-0x7F) have inline data of 1-32 bytes respectively.

**Skip computation:**
```
let push := sub(op, 0x60)
if lt(push, 0x20) { cursor := add(cursor, add(push, 1)) }
```

- For PUSH1 (0x60): `push = 0`, skip = `0 + 1 = 1` byte. Correct (PUSH1 has 1 byte of inline data).
- For PUSH32 (0x7F): `push = 0x1F`, skip = `0x1F + 1 = 0x20 = 32` bytes. Correct.
- For PUSH0 (0x5F): `push = 0x5F - 0x60` underflows to `2^256 - 1`, which is not `lt` 0x20. No skip. Correct (PUSH0 has no inline data).
- For non-PUSH opcodes (e.g., 0x80): `push = 0x80 - 0x60 = 0x20`, which is not `lt` 0x20. No skip. Correct.
- For opcodes below 0x60 (e.g., 0x00): underflow produces huge value, no skip. Correct.

This matches the reference implementation in `LibExtrospectionSlow.sol` which uses `i += op - 0x5f` (with the `for` loop's `i++` providing the additional +1). Both are fuzz-tested against each other.

### 3. Boundary Conditions

**Empty bytecode (length = 0):**
- `isEOFBytecode`: `length >= 2` is false, returns false. Correct.
- Scan functions: `end = cursor`, loop condition `lt(cursor, cursor)` is false, loop never executes. Returns 0. Correct.
- `tryTrimSolidityCBORMetadata`: `length >= 53` is false, returns false. Correct.

**Single byte bytecode (length = 1):**
- `isEOFBytecode`: `length >= 2` is false, returns false. Correct.
- Scan functions: one iteration, reads data[0], processes it. Correct.

**Bytecode ending mid-PUSH (e.g., `[PUSH2, 0xAB]`, length = 2):**
- Iteration 1: reads PUSH2 (0x61), `push = 1`, `cursor += 2`. Now `cursor = bytecode + 3`.
- Loop check: `lt(bytecode + 3, bytecode + 2)` is false. Loop exits.
- PUSH2 opcode itself is recorded in the bitmap; the incomplete inline data is simply not processed. The function does not revert. This is consistent with how the EVM would treat truncated bytecode (the inline bytes would be zeros). This behavior is acceptable and consistent with the reference implementation.

### 4. CBOR Metadata Trimming

**Mask verification:**
- `maskA = 0x0000000000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000`
  - Zeros positions 0-10 (non-metadata bytes from first `mload`)
  - Keeps positions 11-18 (static CBOR: `0xa264`, `ipfs` as `0x69706673`, `0x5822`)
  - Zeros positions 19-31 (start of dynamic IPFS hash)
- `maskB = 0x000000000000000000000000000000000000000000FFFFFFFFFFFF000000FFFF`
  - Zeros positions 0-20 (rest of dynamic IPFS hash)
  - Keeps positions 21-26 (static CBOR: `0x64`, `solc` as `0x736f6c63`, `0x43`)
  - Zeros positions 27-29 (dynamic solc version)
  - Keeps positions 30-31 (static length `0x0033` = 51)

**Hash verification:** I independently computed the keccak256 of the masked 64-byte value and confirmed it matches the expected hash `0x0e55864b80a56accebaca64500e23598f6acfb743a5475323f0b7f2d0d268c62`. The masks and expected hash are consistent.

**Mutation:** On successful trim, `mstore(bytecode, sub(length, 53))` reduces the `bytes` length by 53. The original data remains in memory but is no longer within the logical bounds of the array. This is documented behavior ("NOTE bytecode is mutated in place").

### 5. EOF Detection

`isEOFBytecode` checks that `bytecode.length >= 2` and the first two data bytes equal `0xEF00`.

- The guard `length >= 2` prevents reading out of bounds for short bytecode.
- `mload(add(bytecode, 2))` loads 32 bytes starting at `bytecode + 2`. The `and(..., 0xFFFF)` mask extracts the last two bytes of the 32-byte word, which are at `bytecode + 32` and `bytecode + 33` = `data[0]` and `data[1]`.
- Comparison with `0xEF00` correctly checks `data[0] == 0xEF && data[1] == 0x00`, per EIP-3540 EOF format magic.
- Per EIP-3541, no contract with a `0xEF` first byte can exist on-chain (deployment is rejected), so the `0xEF00` check is sufficient -- there are no false negatives in practice for on-chain bytecode.

### 6. Halting Bitmap Usage in Reachable Scan

The `HALTING_BITMAP` includes: STOP (0x00), RETURN (0xF3), REVERT (0xFD), INVALID (0xFE), SELFDESTRUCT (0xFF), and JUMP (0x56).

- JUMP is correctly included because it is an unconditional jump with no fall-through.
- JUMPI is correctly excluded because it is conditional and can fall through.
- When `halted = 1`, only JUMPDEST (0x5B) un-halts and is recorded. All other opcodes are silently skipped.
- PUSH inline data is correctly skipped even in halted state (the skip logic runs before the halted switch).

This is a linear over-approximation: any JUMPDEST in the bytecode is treated as reachable regardless of whether any JUMP actually targets it. This is a known, documented design choice (not a bug), consistent with the upstream reference from `MrLuit/selfdestruct-detect`.

---

## Findings

No findings.

The library demonstrates careful, correct implementation across all reviewed areas:

1. **Assembly memory safety**: All pointer arithmetic is verified correct. Scratch space usage follows Solidity conventions. The `memory-safe` annotations are accurate -- scan functions only read from allocated memory with no writes, and the CBOR trim function correctly uses scratch space plus a documented in-place mutation.

2. **PUSH skip logic**: The `sub(op, 0x60)` / `lt(push, 0x20)` pattern correctly handles PUSH0 through PUSH32 and all non-PUSH opcodes, leveraging EVM uint256 underflow semantics. Skip amounts are verified equivalent to the reference implementation.

3. **Boundary conditions**: Empty bytecode, single-byte bytecode, and bytecode truncated mid-PUSH are all handled gracefully without reverts or incorrect results.

4. **CBOR metadata trimming**: Masks and expected hash are verified consistent by independent computation. The approach correctly identifies and zeros dynamic fields (IPFS hash, solc version) while preserving static structural bytes for comparison.

5. **EOF detection**: The `0xEF00` magic check is correct per EIP-3540 and sufficient for on-chain bytecode per EIP-3541.

6. **Halting bitmap**: The halt/resume logic is correct. The reachable scan's linear over-approximation is a deliberate, documented design choice with appropriate trade-offs.

7. **Fuzz testing**: Both scan functions are fuzz-tested against independently written reference implementations (`LibExtrospectionSlow`), providing strong confidence in equivalence.
