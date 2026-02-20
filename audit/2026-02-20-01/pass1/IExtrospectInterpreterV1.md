# Audit: IExtrospectInterpreterV1.sol

**Auditor Agent:** A03
**File:** `src/interface/IExtrospectInterpreterV1.sol`
**Branch:** `2026-02-19-metamorphic`
**Lines:** 77

---

## Evidence of Thorough Reading

### Interface/Contract Name

- `IExtrospectInterpreterV1` (interface, line 62)

### Functions

| Function | Visibility | Mutability | Line |
|----------|------------|------------|------|
| `scanOnlyAllowedInterpreterEVMOpcodes(address interpreter) external view returns (bool)` | external | view | 75 |

### Types, Errors, and Constants

No custom types or errors are defined in this file.

**File-level constants:**

| Name | Type | Line(s) | Value (bit positions) |
|------|------|---------|----------------------|
| `NON_STATIC_OPS` | `uint256` | 25–35 | Bits 85, 93, 160–164, 240, 241, 245, 255 |
| `INTERPRETER_DISALLOWED_OPS` | `uint256` | 38–55 | `NON_STATIC_OPS` plus bits 84, 92, 241 (re-stated), 242, 244 |

### Imports (from `../lib/EVMOpcodes.sol`)

All imported constants are `uint8` file-level constants. Verified values:

| Constant | Hex | Bit |
|----------|-----|-----|
| `EVM_OP_CREATE` | 0xF0 | 240 |
| `EVM_OP_CREATE2` | 0xF5 | 245 |
| `EVM_OP_LOG0` | 0xA0 | 160 |
| `EVM_OP_LOG1` | 0xA1 | 161 |
| `EVM_OP_LOG2` | 0xA2 | 162 |
| `EVM_OP_LOG3` | 0xA3 | 163 |
| `EVM_OP_LOG4` | 0xA4 | 164 |
| `EVM_OP_SSTORE` | 0x55 | 85 |
| `EVM_OP_SELFDESTRUCT` | 0xFF | 255 |
| `EVM_OP_CALL` | 0xF1 | 241 |
| `EVM_OP_SLOAD` | 0x54 | 84 |
| `EVM_OP_DELEGATECALL` | 0xF4 | 244 |
| `EVM_OP_CALLCODE` | 0xF2 | 242 |
| `EVM_OP_TSTORE` | 0x5D | 93 |
| `EVM_OP_TLOAD` | 0x5C | 92 |

### Changes on This Branch vs. `main`

Two changes were made to this file on the `2026-02-19-metamorphic` branch:

1. **Pragma bumped** from `^0.8.18` to `^0.8.25` (line 3)
2. **NatSpec added** for `@param interpreter` and `@return` on the interface function (lines 70–73), documenting the return value polarity explicitly

---

## Findings

### A03-1: Pragma change from `^0.8.18` to `^0.8.25` is correct but slightly narrows deployment flexibility — **INFO**

**Lines:** 3

**Description:** The pragma was changed from `^0.8.18` to `^0.8.25` on this branch. This is consistent with the rest of the codebase and with the project's stated convention (all source files use `^0.8.25`). The change is correct.

However, since this is a pure interface file (no assembly, no complex arithmetic), there is no technical reason to require a minimum of 0.8.25 — any compiler `^0.8.18` could compile it. The stricter constraint is a deliberate consistency choice, not a safety requirement. No risk is introduced; the narrower range is acceptable.

**Recommendation:** None. The change is intentional and consistent with project conventions.

---

### A03-2: `NON_STATIC_OPS` is stricter than EIP-214 for `CALL` — **INFO**

**Lines:** 23–33

**Description:** The `NON_STATIC_OPS` constant references EIP-214 in its NatSpec comment (line 23), but includes `EVM_OP_CALL` (0xF1) unconditionally. Per EIP-214 specification, `CALL` is only disallowed in a static context when the `value` argument is non-zero; a zero-value `CALL` is explicitly permitted in a static context. The constant is therefore more conservative than the EIP it references.

This is not a bug — the conservatism is appropriate for the stated security goal. A `true` return from `scanOnlyAllowedInterpreterEVMOpcodes` means no disallowed opcodes were detected, not that the contract is safe; the NatSpec (now present on this branch) correctly notes this. The deviation from strict EIP-214 is undocumented.

**Recommendation:** Optionally add a brief inline comment such as `// conservative: EIP-214 permits zero-value CALL in static context` at the `EVM_OP_CALL` entry in `NON_STATIC_OPS`.

---

### A03-3: Redundant `EVM_OP_CALL` in `INTERPRETER_DISALLOWED_OPS` with potentially misleading comment — **INFO**

**Lines:** 52–55

**Description:** `INTERPRETER_DISALLOWED_OPS` explicitly ORs in `EVM_OP_CALL` (0xF1) at line 55 with the comment: "Redundant with static list for clarity as static list allows 0 value calls." This comment implies that `NON_STATIC_OPS` (referred to as "static list") permits zero-value `CALL`, and that `INTERPRETER_DISALLOWED_OPS` is needed to catch them. In fact, `NON_STATIC_OPS` already includes `EVM_OP_CALL` unconditionally (line 33), so zero-value `CALL` is already captured. The OR is idempotent (`x | x == x`) and produces the correct value, but the comment is inaccurate.

**Recommendation:** Correct the comment to reflect that the OR is redundant with `NON_STATIC_OPS` (which already disallows all `CALL`), not that `NON_STATIC_OPS` permits zero-value calls. For example: `// Redundant with NON_STATIC_OPS (which already disallows all CALL). Restated here for interpreter-level clarity.`

---

### A03-4: Previous finding A03-4 resolved — return value NatSpec now present — **INFO**

**Lines:** 70–73

**Description:** The prior audit pass (2026-02-19-02, A03-4, LOW) identified that the `@return` value polarity was undocumented, risking implementor confusion about whether `true` means "safe" or "not provably unsafe." This finding has been remediated on the current branch: lines 70–73 add:

```
/// @param interpreter The interpreter contract address to scan.
/// @return `true` if only allowed opcodes were found (no disallowed opcodes
/// detected), `false` if any disallowed opcode was detected. A `true`
/// return does NOT guarantee the contract is safe to use as an interpreter.
```

This correctly documents both polarities and the limitation of the guarantee.

**Recommendation:** None. The fix is appropriate.

---

### A03-5: Bitmask arithmetic is correct and overflow-safe — **INFO**

**Lines:** 25–55

**Description:** All imported opcode constants are `uint8` values in the range `[0x00, 0xFF]`, yielding bit positions `[0, 255]`, all of which fit within a `uint256`. The largest shift used is `1 << uint256(EVM_OP_SELFDESTRUCT)` = `1 << 255`, which is exactly the most-significant bit of a `uint256` and does not overflow. The `forge-lint: disable-next-line(incorrect-shift)` annotations are appropriate because the linter flags large shifts as suspicious, but the shifts are intentional in this bitmap encoding scheme.

The repeated inclusion of `EVM_OP_CALL` in both constants is idempotent (`x | x == x`) and produces the correct result.

**Recommendation:** None.

---

### A03-6: Interface exposes no implementation; `INTERPRETER_DISALLOWED_OPS` is unreferenced within this repository — **INFO**

**Lines:** 62–76, 38–55

**Description:** `IExtrospectInterpreterV1` is defined as a pure interface with a single function; no contract in this repository implements it. `INTERPRETER_DISALLOWED_OPS` is a file-level constant defined alongside the interface but is not referenced by any code within this repository. Both serve as a specification for external consumers.

This is not a defect. However, auditors of consuming codebases should verify that `INTERPRETER_DISALLOWED_OPS` is correctly applied against the scan result bitmap, e.g., that implementations check `(scanResult & INTERPRETER_DISALLOWED_OPS) == 0` rather than `(scanResult & INTERPRETER_DISALLOWED_OPS) != 0` (which would invert the safety predicate).

**Recommendation:** None for this repository. Downstream consumers should apply the mask with the correct polarity.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| A03-1 | INFO | Pragma bump from `^0.8.18` to `^0.8.25` is correct and consistent |
| A03-2 | INFO | `NON_STATIC_OPS` conservatively includes all `CALL`; deviation from EIP-214 undocumented |
| A03-3 | INFO | Redundant `EVM_OP_CALL` OR in `INTERPRETER_DISALLOWED_OPS` has a misleading comment |
| A03-4 | INFO | Prior LOW finding (missing `@return` NatSpec) is resolved on this branch |
| A03-5 | INFO | Bitmask arithmetic is correct and overflow-safe |
| A03-6 | INFO | Interface and `INTERPRETER_DISALLOWED_OPS` constant are unimplemented/unreferenced in-repo |

No CRITICAL, HIGH, MEDIUM, or LOW severity findings were identified in the current state of this file. The two changes on the `2026-02-19-metamorphic` branch (pragma bump and NatSpec addition) are both correct. The remaining informational notes are documentation-quality observations and do not represent security risks.
