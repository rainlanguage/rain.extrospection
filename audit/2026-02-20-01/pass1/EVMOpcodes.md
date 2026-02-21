# Audit: EVMOpcodes.sol

**Auditor Agent:** A06
**Date:** 2026-02-20
**File:** `src/lib/EVMOpcodes.sol`
**Pass:** 1 (Security)

---

## Evidence of Thorough Reading

### File Structure

| Lines | Content |
|-------|---------|
| 1 | SPDX license identifier: `LicenseRef-DCL-1.0` |
| 2 | Copyright notice |
| 3 | `pragma solidity ^0.8.25;` |
| 5–10 | NatSpec file-level comment describing opcode constants and derived bitmaps |
| 12–182 | Individual EVM opcode `uint8` constants (84 constants) |
| 184–194 | `HALTING_BITMAP` derived `uint256` constant with NatSpec and forge-lint suppressions |
| 196–210 | `METAMORPHIC_OPS` derived `uint256` constant with NatSpec and forge-lint suppressions |

### Constants — Opcode Values (84 individual constants)

All constants are `uint8` file-level constants. Grouped by EVM instruction category:

| Line(s) | Name(s) | Value(s) |
|---------|---------|---------|
| 12 | `EVM_OP_STOP` | `0x00` |
| 14–24 | `EVM_OP_ADD` … `EVM_OP_SIGNEXTEND` | `0x01` – `0x0B` |
| 26–40 | `EVM_OP_LT` … `EVM_OP_SAR` | `0x10` – `0x1D` |
| 42 | `EVM_OP_SHA3` | `0x20` |
| 44–65 | `EVM_OP_ADDRESS` … `EVM_OP_EXTCODEHASH` | `0x30` – `0x3F` |
| 66–79 | `EVM_OP_BLOCKHASH` … `EVM_OP_BLOBBASEFEE` | `0x40` – `0x4A` |
| 81–97 | `EVM_OP_POP` … `EVM_OP_MCOPY` | `0x50` – `0x5E` |
| 99–131 | `EVM_OP_PUSH0` … `EVM_OP_PUSH32` | `0x5F` – `0x7F` |
| 133–148 | `EVM_OP_DUP1` … `EVM_OP_DUP16` | `0x80` – `0x8F` |
| 150–165 | `EVM_OP_SWAP1` … `EVM_OP_SWAP16` | `0x90` – `0x9F` |
| 167–171 | `EVM_OP_LOG0` … `EVM_OP_LOG4` | `0xA0` – `0xA4` |
| 173–182 | `EVM_OP_CREATE` … `EVM_OP_SELFDESTRUCT` | `0xF0` – `0xFF` |

### Constants — Derived Bitmaps (2 constants)

| Line | Name | Type | Composed of |
|------|------|------|-------------|
| 189–194 | `HALTING_BITMAP` | `uint256` | `STOP \| RETURN \| REVERT \| INVALID \| SELFDESTRUCT \| JUMP` |
| 206–210 | `METAMORPHIC_OPS` | `uint256` | `SELFDESTRUCT \| DELEGATECALL \| CALLCODE \| CREATE \| CREATE2` |

### Errors

None defined in this file.

### Functions

None defined in this file.

### Forge-lint Suppressions

Six `//forge-lint: disable-next-line(incorrect-shift)` comments appear at lines 188, 190, 193, 205, 207, and 209. Each suppresses the linter's `incorrect-shift` diagnostic, which fires when it sees `(1 << constant)` and suspects the developer may have intended `(constant << 1)`. The suppressions are intentional and correct: the bitmap design requires setting bit N for opcode 0xN, which is `(1 << N)`.

---

## Security Review

### 1. Opcode Value Correctness

All 84 opcode constants were verified against the EVM Yellow Paper and EIP specifications current through Cancun (EIP-1153, EIP-4399, EIP-4844, EIP-5656, EIP-6780). Every constant matches its canonical specification value exactly.

Cross-checks performed on contiguous ranges (which are the most error-prone due to off-by-one potential):

| Range | Expected span | Verified |
|-------|--------------|---------|
| PUSH0–PUSH32 (lines 99–131) | `0x5F`–`0x7F` (33 opcodes) | All correct |
| DUP1–DUP16 (lines 133–148) | `0x80`–`0x8F` (16 opcodes) | All correct |
| SWAP1–SWAP16 (lines 150–165) | `0x90`–`0x9F` (16 opcodes) | All correct |
| LOG0–LOG4 (lines 167–171) | `0xA0`–`0xA4` (5 opcodes) | All correct |

Cancun-era opcodes specifically verified:

| Name | Line | Value | EIP |
|------|------|-------|-----|
| `EVM_OP_TLOAD` | 95 | `0x5C` | EIP-1153 |
| `EVM_OP_TSTORE` | 96 | `0x5D` | EIP-1153 |
| `EVM_OP_MCOPY` | 97 | `0x5E` | EIP-5656 |
| `EVM_OP_BLOBHASH` | 78 | `0x49` | EIP-4844 |
| `EVM_OP_BLOBBASEFEE` | 79 | `0x4A` | EIP-4844 |

System opcodes in the `0xF0`–`0xFF` range (sparse, gap-prone) verified:

| Name | Line | Value | Gap before next |
|------|------|-------|----------------|
| `EVM_OP_CREATE` | 173 | `0xF0` | — |
| `EVM_OP_CALL` | 174 | `0xF1` | — |
| `EVM_OP_CALLCODE` | 175 | `0xF2` | — |
| `EVM_OP_RETURN` | 176 | `0xF3` | — |
| `EVM_OP_DELEGATECALL` | 177 | `0xF4` | — |
| `EVM_OP_CREATE2` | 178 | `0xF5` | gap: `0xF6`–`0xF9` undefined |
| `EVM_OP_STATICCALL` | 179 | `0xFA` | gap: `0xFB`–`0xFC` undefined |
| `EVM_OP_REVERT` | 180 | `0xFD` | — |
| `EVM_OP_INVALID` | 181 | `0xFE` | — |
| `EVM_OP_SELFDESTRUCT` | 182 | `0xFF` | — |

The gaps at `0xF6`–`0xF9` and `0xFB`–`0xFC` are correct: those bytes have no assigned opcode in the current EVM specification and act as `INVALID`.

### 2. HALTING_BITMAP Construction

The bitmap is defined at lines 189–194:

```solidity
uint256 constant HALTING_BITMAP = (1 << EVM_OP_STOP) | (1 << EVM_OP_RETURN) | (1 << EVM_OP_REVERT)
    | (1 << EVM_OP_INVALID) | (1 << EVM_OP_SELFDESTRUCT)
    | (1 << EVM_OP_JUMP);
```

Membership verification:

| Opcode | Value (decimal) | Bit position | In bitmap |
|--------|----------------|--------------|-----------|
| `STOP` | 0 | 0 | Yes |
| `JUMP` | 86 | 86 | Yes |
| `RETURN` | 243 | 243 | Yes |
| `REVERT` | 253 | 253 | Yes |
| `INVALID` | 254 | 254 | Yes |
| `SELFDESTRUCT` | 255 | 255 | Yes |

All five canonical execution-terminating opcodes are present. `JUMP` (0x56) is additionally included because the reachable-scan purpose requires pausing linear scanning at any unconditional branch. `JUMPI` (0x57) is correctly absent: it is a conditional branch and the fall-through path must still be scanned linearly.

Shift arithmetic boundary: the maximum shift amount is `EVM_OP_SELFDESTRUCT = 0xFF = 255`. A `uint256` holds bits 0–255, so `1 << 255` sets the most-significant bit without overflow. All shifts are within bounds.

Computed bitmap value: `0xE008000000000000000000000000000000000000004000000000000000000001`.

### 3. METAMORPHIC_OPS Construction

The bitmap is defined at lines 206–210:

```solidity
uint256 constant METAMORPHIC_OPS = (1 << uint256(EVM_OP_SELFDESTRUCT)) | (1 << uint256(EVM_OP_DELEGATECALL))
    | (1 << uint256(EVM_OP_CALLCODE)) | (1 << uint256(EVM_OP_CREATE))
    | (1 << uint256(EVM_OP_CREATE2));
```

Membership verification:

| Opcode | Value (decimal) | Bit position | In bitmap |
|--------|----------------|--------------|-----------|
| `CREATE` | 240 | 240 | Yes |
| `CALLCODE` | 242 | 242 | Yes |
| `DELEGATECALL` | 244 | 244 | Yes |
| `CREATE2` | 245 | 245 | Yes |
| `SELFDESTRUCT` | 255 | 255 | Yes |

All five required metamorphic-risk opcodes are present and correct. The explicit `uint256(...)` casts are a stylistic difference from `HALTING_BITMAP` but have no semantic effect in Solidity constant expressions, which are evaluated at compile time with arbitrary precision.

Computed bitmap value: `0x8035000000000000000000000000000000000000000000000000000000000000`.

### 4. Constant-Expression Type Safety

In Solidity `^0.8.25`, constant expressions are evaluated at compile time using arbitrary-precision integer arithmetic, regardless of the declared types of the operands. This means that `(1 << EVM_OP_SELFDESTRUCT)` where `EVM_OP_SELFDESTRUCT` is `uint8 = 0xFF` computes correctly to `2^255` before the result is stored as `uint256`. There is no runtime truncation, no intermediate `uint8` overflow, and no loss of precision. The forge-lint suppressions confirm that the shift direction is intentional.

### 5. EVM_OP_DIFFICULTY Naming (Informational)

`EVM_OP_DIFFICULTY` at line 71 is assigned value `0x44`, which is correct. EIP-4399 (The Merge, Paris fork) renamed opcode `0x44` from `DIFFICULTY` to `PREVRANDAO`. The constant name in this file uses the pre-Merge name. This does not affect the correctness of the opcode value or any bitmap, and is purely a naming matter. It is flagged here as informational context for maintainers.

### 6. Cast Style Inconsistency (Informational)

`HALTING_BITMAP` uses `(1 << EVM_OP_X)` without explicit cast; `METAMORPHIC_OPS` uses `(1 << uint256(EVM_OP_X))` with explicit cast. Both are correct in Solidity constant expressions. The inconsistency is cosmetic and does not introduce any security risk.

### 7. No Errors or Functions

The file contains no `error` declarations and no `function` definitions. It is a pure constants file. There are no access control, revert path, or function-logic issues to evaluate.

### 8. Pragma Consistency

The file uses `pragma solidity ^0.8.25`, consistent with all other source files in the project as documented in `CLAUDE.md`. The file contains no assembly and no runtime code; it cannot be affected by compiler version variations within the `^0.8.25` range.

---

## Findings

No security findings.

All opcode constant values are correct against the EVM specification through Cancun. `HALTING_BITMAP` correctly includes all six required entries (STOP, RETURN, REVERT, INVALID, SELFDESTRUCT, and unconditional JUMP) and correctly excludes JUMPI. `METAMORPHIC_OPS` correctly includes all five required entries (SELFDESTRUCT, DELEGATECALL, CALLCODE, CREATE, CREATE2). All shift arithmetic is within `uint256` bounds (maximum shift amount 255, which sets the MSB without overflow). Two informational notes are recorded but neither represents a security issue:

1. `EVM_OP_DIFFICULTY` uses the pre-Merge opcode name; the value `0x44` is correct.
2. `HALTING_BITMAP` and `METAMORPHIC_OPS` use inconsistent cast styles for shift operands; both are semantically correct in Solidity constant expressions.
