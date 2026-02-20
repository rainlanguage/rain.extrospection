# Audit: LibExtrospectMetamorphic.sol

**Auditor Agent:** A09
**Date:** 2026-02-20
**File:** `src/lib/LibExtrospectMetamorphic.sol`
**Pass:** 1 (Security)

---

## Evidence of Thorough Reading

### Library Name

`LibExtrospectMetamorphic` — declared as `library` at line 12.

### Functions

| Name | Line | Visibility | Mutability |
|------|------|------------|------------|
| `scanMetamorphicRisk(bytes memory)` | 21 | internal | pure |
| `checkNotMetamorphic(bytes memory)` | 27 | internal | pure |

### Errors

| Name | Line | Parameters |
|------|------|------------|
| `Metamorphic` | 15 | `uint256 riskyOpcodes` |

### Constants

None defined in this file. The file imports:
- `LibExtrospectBytecode` from `./LibExtrospectBytecode.sol` (line 5)
- `METAMORPHIC_OPS` from `./EVMOpcodes.sol` (line 6)

### Imports

| Name | Source | Line |
|------|--------|------|
| `LibExtrospectBytecode` | `./LibExtrospectBytecode.sol` | 5 |
| `METAMORPHIC_OPS` | `./EVMOpcodes.sol` | 6 |

### File Structure

| Lines | Content |
|-------|---------|
| 1 | SPDX license identifier: `LicenseRef-DCL-1.0` |
| 2 | Copyright notice |
| 3 | `pragma solidity ^0.8.25;` |
| 5–6 | Imports |
| 8–11 | NatSpec `@title` and `@notice` for the library |
| 12–33 | Library body |
| 13–15 | Error: `Metamorphic(uint256 riskyOpcodes)` |
| 17–23 | Function: `scanMetamorphicRisk` |
| 25–32 | Function: `checkNotMetamorphic` |

---

## Security Review

### 1. Correctness of the Core Bitmap Masking

`scanMetamorphicRisk` (line 22) computes:

```solidity
riskyOpcodes = LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode) & METAMORPHIC_OPS;
```

`METAMORPHIC_OPS` (defined in `EVMOpcodes.sol` lines 206–210) is:

```
(1 << 0xFF) | (1 << 0xF4) | (1 << 0xF2) | (1 << 0xF0) | (1 << 0xF5)
```

which corresponds to bits 255, 244, 242, 240, and 245 — all within the valid `uint256` range. The bitwise AND correctly isolates exactly those five bits from the reachable scan result. No bit out of range, no overflow possible.

### 2. Reachable Scan Used, Not Present Scan

`scanMetamorphicRisk` calls `scanEVMOpcodesReachableInBytecode`, not `scanEVMOpcodesPresentInBytecode`. This is the correct, security-sound choice: the reachable scan skips PUSH inline data and respects JUMP/halt-based control flow, preventing false negatives caused by opcode bytes embedded as PUSH data from being mistaken for actual opcodes. Crucially, it also provides defense against a known bytecode manipulation technique where SELFDESTRUCT bytes are embedded in the CBOR metadata suffix and would appear in a naive linear scan but are not executable.

### 3. SELFDESTRUCT in Both HALTING_BITMAP and METAMORPHIC_OPS

`SELFDESTRUCT` (0xFF) is a member of both `HALTING_BITMAP` (used by the reachable scan to pause scanning) and `METAMORPHIC_OPS` (used by this library to flag risk). This requires careful analysis.

In `scanEVMOpcodesReachableInBytecode` (LibExtrospectBytecode.sol lines 177–185), when `halted == 0` and the current opcode is SELFDESTRUCT:

1. `bytesReachable` is ORed with `shl(0xFF, 1)` — SELFDESTRUCT is **recorded as reachable**.
2. `and(shl(op, 1), haltingMask)` is nonzero — `halted` is set to 1.

Because step 1 executes before step 2 within the same `case 0` branch, SELFDESTRUCT is correctly included in the reachable bitmap before halting is triggered. The subsequent AND with `METAMORPHIC_OPS` in `scanMetamorphicRisk` will therefore correctly detect it. There is no missed-detection issue.

### 4. checkNotMetamorphic Cannot Be Bypassed by EOF Bytecode

`checkNotMetamorphic` calls `scanMetamorphicRisk`, which calls `scanEVMOpcodesReachableInBytecode`, which calls `checkNotEOFBytecode` (LibExtrospectBytecode.sol line 157). EOF bytecode (`0xEF00` prefix) causes an unconditional revert with `EOFBytecodeNotSupported` before any scanning occurs. There is no path through `checkNotMetamorphic` that silently passes EOF bytecode: it will always revert. This is conservative (safe-by-revert).

### 5. checkNotMetamorphic Cannot Be Bypassed by Dead-Code Embedding

If a metamorphic opcode appears after an unconditional halt in the bytecode but before any JUMPDEST, the reachable scan will not set its bit in `bytesReachable` (because `halted == 1` at that point and only JUMPDEST can un-halt). Such an opcode would not be flagged by `checkNotMetamorphic`. This is the intended design of the reachable scan (conservative but sound over-approximation for reachable code) and is consistent with the upstream reference implementation. A contract that contains SELFDESTRUCT only in truly unreachable dead-code regions cannot execute it, so not flagging it is correct. The reachable scan also treats every JUMPDEST as potentially reachable regardless of whether any JUMP actually targets it, which means the over-approximation errs on the side of false positives (flagging safe contracts) rather than false negatives (passing dangerous ones).

### 6. Error Handling Completeness

`checkNotMetamorphic` reverts with the custom error `Metamorphic(riskyOpcodes)` if any metamorphic ops are reachable, passing the full bitmask of detected risky opcodes to the error. This is complete: callers receive enough information to determine which specific opcodes triggered the revert. No string revert messages are used. The function is `pure`, so there are no state-change side effects to consider. There are no silent failure paths.

### 7. Empty Bytecode Handling

When `bytecode` is empty (`length == 0`), `scanEVMOpcodesReachableInBytecode` returns 0 (the loop condition `lt(cursor, end)` is immediately false). `scanMetamorphicRisk` returns `0 & METAMORPHIC_OPS = 0`. `checkNotMetamorphic` therefore passes without reverting for empty bytecode. This is the correct and documented behavior: an empty contract has no reachable metamorphic ops.

### 8. Pragma Consistency

The file uses `pragma solidity ^0.8.25`, consistent with all other source files in the project. The library has no assembly, no custom types, and only pure arithmetic and function calls, so compiler version differences within the `^0.8.25` range cannot introduce behavioral differences.

### 9. NatSpec Accuracy

- `scanMetamorphicRisk` documents `@return riskyOpcodes` as "Zero if no metamorphic risk opcodes are reachable" — correct.
- `checkNotMetamorphic` states it "Reverts if any metamorphic risk opcodes are reachable" — correct; it calls `scanMetamorphicRisk` (which uses the reachable scan) and reverts on nonzero.
- No discrepancy between documentation and implementation was found.

---

## Findings

No security findings.

The library is a minimal, correct two-function wrapper over `LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode` and the `METAMORPHIC_OPS` bitmap. Every security-relevant property was verified:

1. **Bitmap masking is correct**: `METAMORPHIC_OPS` bits 240, 242, 244, 245, and 255 are all within `uint256` range; the AND operation correctly isolates them.
2. **Reachable scan is used**: `scanEVMOpcodesReachableInBytecode` is called, not the weaker `scanEVMOpcodesPresentInBytecode`, preventing evasion via PUSH-embedded opcode bytes or CBOR metadata tricks.
3. **SELFDESTRUCT dual-membership is safe**: The opcode is recorded in the reachable bitmap before the halting flag is set, so it is never missed.
4. **EOF reverts propagate correctly**: `checkNotMetamorphic` cannot be silently bypassed with EOF input; it will always revert via the inner `checkNotEOFBytecode` guard.
5. **Error handling is complete**: Custom error `Metamorphic(riskyOpcodes)` is used; no string messages; no silent failure paths.
6. **Empty bytecode is handled correctly**: Returns 0 / does not revert, as expected.
