# Audit: IExtrospectInterpreterV1.sol

**Auditor Agent:** A03
**File:** `src/interface/IExtrospectInterpreterV1.sol`
**Lines:** 73

---

## Evidence of Thorough Reading

### Interface/Contract Name

- `IExtrospectInterpreterV1` (interface, line 62)

### Functions

| Function | Line |
|----------|------|
| `scanOnlyAllowedInterpreterEVMOpcodes(address interpreter) external view returns (bool)` | 71 |

### Types, Errors, and Constants

No custom types or errors are defined in this file.

**File-level constants:**

| Name | Type | Line(s) |
|------|------|---------|
| `NON_STATIC_OPS` | `uint256` | 25-35 |
| `INTERPRETER_DISALLOWED_OPS` | `uint256` | 38-55 |

### Imports (from `../lib/EVMOpcodes.sol`)

`EVM_OP_CREATE` (0xF0), `EVM_OP_CREATE2` (0xF5), `EVM_OP_LOG0` (0xA0), `EVM_OP_LOG1` (0xA1), `EVM_OP_LOG2` (0xA2), `EVM_OP_LOG3` (0xA3), `EVM_OP_LOG4` (0xA4), `EVM_OP_SSTORE` (0x55), `EVM_OP_SELFDESTRUCT` (0xFF), `EVM_OP_CALL` (0xF1), `EVM_OP_SLOAD` (0x54), `EVM_OP_DELEGATECALL` (0xF4), `EVM_OP_CALLCODE` (0xF2), `EVM_OP_TSTORE` (0x5D), `EVM_OP_TLOAD` (0x5C)

---

## Findings

### A03-1 [INFO] `NON_STATIC_OPS` is stricter than EIP-214 for `CALL`

**Lines:** 33, 23

**Description:** The `NON_STATIC_OPS` constant references EIP-214 in its NatSpec comment (line 23), but includes `CALL` (0xF1) unconditionally. EIP-214 only disallows `CALL` when the `value` argument is non-zero; a zero-value `CALL` is permitted in a static context. Including `CALL` unconditionally makes `NON_STATIC_OPS` strictly more conservative than EIP-214.

This is not a bug -- being more conservative is defensively correct for the stated safety goal. However, the NatSpec links to EIP-214 as a reference without noting the deviation, which could mislead a reader into thinking this constant is an exact 1:1 encoding of EIP-214. A developer who inherits or relies on this constant elsewhere might incorrectly assume that `CALL` is always prohibited in static contexts, when in fact the EVM permits zero-value calls.

**Recommendation:** Add a brief comment noting that `CALL` is included conservatively and that EIP-214 only prohibits `CALL` with non-zero `value`.

---

### A03-2 [INFO] `SELFDESTRUCT` semantics changed post-Dencun (EIP-6780)

**Lines:** 31

**Description:** `SELFDESTRUCT` (0xFF) is included in `NON_STATIC_OPS`. Post-Dencun (EIP-6780), `SELFDESTRUCT` no longer destroys the contract except when called in the same transaction as `CREATE`/`CREATE2` that deployed it. It now behaves as a simple ether-transfer in most cases.

However, `SELFDESTRUCT` remains disallowed in static call contexts by the EVM, so its inclusion in `NON_STATIC_OPS` remains technically correct. Additionally, `SELFDESTRUCT` is deprecated and may be fully removed in a future hard fork. No action is strictly required, but awareness is warranted.

**Recommendation:** No change required. Optionally add a comment noting that `SELFDESTRUCT` is deprecated per EIP-6780 but remains static-disallowed.

---

### A03-3 [INFO] Redundant `CALL` in `INTERPRETER_DISALLOWED_OPS`

**Lines:** 54-55

**Description:** `INTERPRETER_DISALLOWED_OPS` explicitly ORs in `EVM_OP_CALL` with the comment "Redundant with static list for clarity as static list allows 0 value calls." This comment is slightly confusing because `NON_STATIC_OPS` actually does NOT allow zero-value calls -- it blanket-disallows all `CALL`. The comment reads as though `NON_STATIC_OPS` permits zero-value calls and only `INTERPRETER_DISALLOWED_OPS` catches them, but in reality `CALL` is already fully disallowed by `NON_STATIC_OPS`.

The bitwise operation `x | x == x`, so the redundancy is harmless at the value level. The issue is solely about the misleading comment.

**Recommendation:** Clarify the comment. For example: "Redundant with NON_STATIC_OPS for clarity. NON_STATIC_OPS conservatively disallows all CALL, but we restate it here to make the interpreter restriction explicit."

---

### A03-4 [LOW] No guidance to implementors on what `false` return means operationally

**Lines:** 63-71

**Description:** The interface NatSpec states the function detects reasons why a contract is "definitely UNSAFE" and that there is "no way to simply determine if a contract is safe." This is a good caveat. However, the return type is a bare `bool` with no documentation on its semantics. A `true` return presumably means "no disallowed opcodes found" (which does NOT mean safe), while `false` means "disallowed opcodes detected" (definitely unsafe). But neither the function NatSpec nor the return value is documented with this polarity.

An implementor could reasonably interpret `true` as "safe" rather than "not provably unsafe," or could invert the polarity (returning `true` for unsafe). The comment on the function body (lines 63-69) describes the scan behavior but does not specify what the return value means.

**Recommendation:** Add explicit NatSpec for the return value, e.g.:
```
/// @return `true` if only allowed opcodes were found (no disallowed opcodes detected),
/// `false` if any disallowed opcode was detected. A `true` return does NOT guarantee
/// the contract is safe to use as an interpreter.
```

---

### A03-5 [INFO] `NON_STATIC_OPS` does not include `TLOAD` but `INTERPRETER_DISALLOWED_OPS` does

**Lines:** 35, 43-44

**Description:** `TLOAD` (0x5C) is NOT disallowed in a static call context by the EVM. EIP-1153 only disallows `TSTORE` in static contexts, not `TLOAD`. The code correctly excludes `TLOAD` from `NON_STATIC_OPS` and only includes it in `INTERPRETER_DISALLOWED_OPS` with the rationale "Interpreter cannot tstore so it has no reason to tload." This is logically sound and correctly modeled. Noting this for completeness.

**Recommendation:** None. The modeling is correct.

---

### A03-6 [INFO] Bitmask arithmetic is correct and safe

**Lines:** 25-55

**Description:** Verified that all imported opcode constants are `uint8` values (0x00-0xFF), so all bit positions are in the range 0-255, which fits within a `uint256`. The `1 << uint256(EVM_OP_*)` expressions will never overflow or produce zero. The bitwise OR composition is idempotent for duplicate entries (CALL appears twice, which is harmless). The `forge-lint: disable-next-line(incorrect-shift)` pragmas are appropriate because the shifts are intentionally large (e.g., shifting by 255 for SELFDESTRUCT) but correct for this bitmask encoding scheme.

**Recommendation:** None.

---

### A03-7 [INFO] Interface has no implementation in this repository

**Lines:** 62-72

**Description:** `IExtrospectInterpreterV1` is defined as an interface with a single function, but no contract in this repository implements it. The `INTERPRETER_DISALLOWED_OPS` constant is defined at file scope but is not referenced by any code within this repository. This means the constant and the interface serve as a specification for external consumers.

This is not a defect, but it means the correctness of how `INTERPRETER_DISALLOWED_OPS` is actually used in opcode scanning cannot be verified from this repository alone.

**Recommendation:** None, but auditors of consuming codebases should verify that `INTERPRETER_DISALLOWED_OPS` is correctly applied against the scan result bitmask (e.g., `(scan & INTERPRETER_DISALLOWED_OPS) == 0`).

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| A03-1 | INFO | `NON_STATIC_OPS` is stricter than EIP-214 for `CALL` |
| A03-2 | INFO | `SELFDESTRUCT` semantics changed post-Dencun (EIP-6780) |
| A03-3 | INFO | Redundant `CALL` in `INTERPRETER_DISALLOWED_OPS` with misleading comment |
| A03-4 | LOW | No guidance to implementors on what `false` return means operationally |
| A03-5 | INFO | `NON_STATIC_OPS` correctly excludes `TLOAD`; `INTERPRETER_DISALLOWED_OPS` correctly includes it |
| A03-6 | INFO | Bitmask arithmetic is correct and safe |
| A03-7 | INFO | Interface has no implementation in this repository |

No CRITICAL, HIGH, or MEDIUM severity findings were identified. The file is a well-structured interface definition with correctly computed bitmask constants. The primary actionable finding (A03-4, LOW) relates to insufficient documentation of the return value polarity, which could lead to implementor confusion.
