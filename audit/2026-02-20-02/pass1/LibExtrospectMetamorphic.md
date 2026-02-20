# Security Audit: LibExtrospectMetamorphic.sol

**Auditor:** A04
**Date:** 2026-02-20
**File:** `src/lib/LibExtrospectMetamorphic.sol`
**Commit branch:** 2026-02-19-metamorphic

---

## Evidence of Thorough Reading

### Library/Contract Name

`LibExtrospectMetamorphic` (library, line 12)

### Functions

| Function | Line | Visibility | Mutability |
|---|---|---|---|
| `scanMetamorphicRisk(bytes memory bytecode)` | 21 | `internal` | `pure` |
| `checkNotMetamorphic(bytes memory bytecode)` | 27 | `internal` | `pure` |

### Types, Errors, and Constants

| Kind | Name | Line |
|---|---|---|
| Error | `Metamorphic(uint256 riskyOpcodes)` | 15 |

No custom types or constants are defined in this file. The library imports `METAMORPHIC_OPS` (a `uint256` bitmap constant) from `EVMOpcodes.sol` and `LibExtrospectBytecode` from `LibExtrospectBytecode.sol`.

### Dependency Summary

- `scanMetamorphicRisk` delegates to `LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode)` and masks the result with `METAMORPHIC_OPS`.
- `checkNotMetamorphic` calls `scanMetamorphicRisk` and reverts with `Metamorphic(riskyOpcodes)` if the result is non-zero.
- `METAMORPHIC_OPS` (defined at `EVMOpcodes.sol` line 206) is: `(1 << SELFDESTRUCT) | (1 << DELEGATECALL) | (1 << CALLCODE) | (1 << CREATE) | (1 << CREATE2)`, i.e., opcodes 0xFF, 0xF4, 0xF2, 0xF0, 0xF5.
- `scanEVMOpcodesReachableInBytecode` (in `LibExtrospectBytecode.sol` line 165) performs a linear over-approximation: it scans bytecode sequentially, skipping PUSH* inline data, halting at HALTING_BITMAP opcodes (STOP, RETURN, REVERT, INVALID, SELFDESTRUCT, JUMP), and resuming at the next JUMPDEST. It rejects EOF bytecode.

---

## Findings

### A04-1: SELFDESTRUCT deprecated post-Dencun (EIP-6780) but still flagged -- INFO

**Severity:** INFO

**Description:** Since the Dencun upgrade (March 2024), `SELFDESTRUCT` (0xFF) no longer destroys contracts except in the same transaction they were created. This means on post-Dencun chains, the presence of a reachable `SELFDESTRUCT` alone does not enable the classic metamorphic attack (destroy-and-redeploy at the same address).

However, `SELFDESTRUCT` remains a valid opcode and still sends the contract's ETH balance to a target. Including it in the metamorphic risk bitmap is a conservative, defense-in-depth choice: it flags contracts that historically could have been metamorphic, and it protects against chains or future forks that may restore the original behavior.

**Recommendation:** No code change needed. This is documented behavior and the conservative approach is appropriate for a security library. Consider adding a NatDoc note that the bitmap is intentionally conservative regarding post-Dencun `SELFDESTRUCT` semantics.

---

### A04-2: Over-approximation by design -- reachability scan may produce false positives -- INFO

**Severity:** INFO

**Description:** The reachability scan in `scanEVMOpcodesReachableInBytecode` is an over-approximation. It treats every `JUMPDEST` after a halt as potentially reachable, even if no `JUMP`/`JUMPI` instruction ever targets that `JUMPDEST`. This means dead code behind a `JUMPDEST` will be reported as reachable.

For a security library, over-approximation is the correct design choice: it may produce false positives (flagging safe contracts as risky) but should never produce false negatives (missing genuinely risky contracts).

The library NatDoc at line 9-11 and the function NatDoc at line 150-157 of `LibExtrospectBytecode.sol` correctly document this as an over-approximation.

**Recommendation:** No code change needed. The over-approximation is well-documented and appropriate for security scanning.

---

### A04-3: No runtime protection against CALL with value forwarding (metamorphic via proxy pattern) -- INFO

**Severity:** INFO

**Description:** A contract that contains only `CALL` (0xF1) but none of the five metamorphic opcodes will pass `checkNotMetamorphic`, yet a `CALL` with value to a `SELFDESTRUCT`-containing proxy is a known attack vector in pre-Dencun environments. The `CALL` opcode is not included in `METAMORPHIC_OPS` because nearly all useful contracts contain `CALL`, and flagging it would make the check useless.

This is a known design tradeoff. `DELEGATECALL` and `CALLCODE` are correctly flagged because they execute callee code in the caller's context and can thus destroy the calling contract.

**Recommendation:** No code change needed. This is a well-understood limitation.

---

### A04-4: EOF bytecode correctly rejected -- no bypass possible -- INFO

**Severity:** INFO

**Description:** Both `scanMetamorphicRisk` and `checkNotMetamorphic` correctly reject EOF bytecode (prefix 0xEF00) by delegating to `scanEVMOpcodesReachableInBytecode`, which calls `checkNotEOFBytecode` before scanning. This prevents misinterpreting EOF container format as legacy opcodes.

EOF (EIP-7692) uses a fundamentally different code structure. Scanning it with the legacy opcode scanner would produce meaningless results. The revert with `EOFBytecodeNotSupported()` is the correct behavior.

The EOF check in `isEOFBytecode` (line 34-41 of `LibExtrospectBytecode.sol`) correctly requires `bytecode.length >= 2` before reading the two-byte magic, avoiding out-of-bounds reads for 0-byte and 1-byte inputs.

**Recommendation:** No code change needed. When EOF is deployed on mainnet, a separate EOF-aware scanner will be needed, but that is a future feature, not a current bug.

---

### A04-5: Empty bytecode handled correctly -- INFO

**Severity:** INFO

**Description:** Empty bytecode (`hex""`, length 0):
- `isEOFBytecode` returns false (length < 2, skips check).
- `checkNotEOFBytecode` does not revert.
- `scanEVMOpcodesReachableInBytecode` enters the for-loop with `cursor == end`, so the loop body never executes, returning `bytesReachable = 0`.
- `scanMetamorphicRisk` returns `0 & METAMORPHIC_OPS = 0`.
- `checkNotMetamorphic` does not revert.

This is correct: an empty contract has no opcodes and no metamorphic risk. This is confirmed by the test `testScanMetamorphicRiskEmpty` and `testCheckNotMetamorphicEmpty`.

**Recommendation:** No change needed.

---

### A04-6: Single-byte bytecode edge case handled correctly -- INFO

**Severity:** INFO

**Description:** A single-byte bytecode (e.g., `hex"FF"` for `SELFDESTRUCT` or `hex"60"` for `PUSH1` with truncated data):
- Not EOF (length < 2).
- Scanner reads the one byte as an opcode. If it is a PUSH opcode (0x60-0x7F), `cursor` advances past the end (truncated PUSH data), and the loop terminates. The opcode itself is still recorded correctly before the skip.
- If the single byte is `SELFDESTRUCT` (0xFF), it is correctly flagged as reachable.

This is sound behavior: truncated PUSH data at the end of bytecode is treated as if the PUSH opcode is present (which it is) but with missing operand bytes. The EVM would trap on this at runtime anyway, and the opcode itself is correctly recorded.

**Recommendation:** No change needed.

---

### A04-7: `METAMORPHIC_OPS` bitmap completeness review -- INFO

**Severity:** INFO

**Description:** The `METAMORPHIC_OPS` bitmap includes:
- `SELFDESTRUCT` (0xFF) -- direct contract destruction
- `DELEGATECALL` (0xF4) -- arbitrary code execution in caller's context
- `CALLCODE` (0xF2) -- deprecated equivalent of `DELEGATECALL`
- `CREATE` (0xF0) -- can deploy child contracts
- `CREATE2` (0xF5) -- can deploy children at deterministic/reusable addresses

This set is consistent with the a16z metamorphic contract detector and standard industry practice. `CREATE` and `CREATE2` are included because they can be used in factory patterns that participate in metamorphic redeployment schemes.

Opcodes NOT included but sometimes discussed in metamorphic contexts:
- `CALL` (0xF1): Excluded because it does not execute in the caller's storage context. Including it would flag nearly all contracts. Correct exclusion.
- `STATICCALL` (0xFA): Read-only, cannot cause state changes. Correct exclusion.

**Recommendation:** No change needed. The bitmap is complete for the intended threat model.

---

### A04-8: Revert error encoding is correct and informative -- INFO

**Severity:** INFO

**Description:** The `Metamorphic(uint256 riskyOpcodes)` error includes the bitmap of detected risky opcodes. This allows callers and off-chain tooling to decode exactly which metamorphic opcodes were found. The error selector is deterministic (`keccak256("Metamorphic(uint256)")[:4]`), and the ABI encoding is standard.

The test file `LibExtrospectMetamorphic.checkNotMetamorphic.t.sol` verifies the exact error selector and parameter value via `abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk)` in all revert test cases.

**Recommendation:** No change needed.

---

### A04-9: `scanMetamorphicRisk` relies entirely on downstream `scanEVMOpcodesReachableInBytecode` correctness -- LOW

**Severity:** LOW

**Description:** `scanMetamorphicRisk` is a one-line composition:

```solidity
riskyOpcodes = LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode) & METAMORPHIC_OPS;
```

If there is any bug in the reachability scanner (e.g., incorrect PUSH data skipping, incorrect halting logic), it would propagate silently through `scanMetamorphicRisk`. This is mitigated by:
1. Fuzz tests comparing the production scanner against a slow reference implementation (`LibExtrospectionSlow.scanMetamorphicRiskSlow`).
2. The slow reference itself delegates to `scanEVMOpcodesReachableInBytecodeSlow`, which uses a straightforward Solidity loop.
3. Both production and reference implementations have identical algorithmic structure.

I verified the PUSH skip logic:
- Production: `push = op - 0x60`; skip = `push + 1` bytes. For PUSH1 (0x60): skip 1. For PUSH32 (0x7F): skip 32.
- Reference: skip = `op - 0x5F` bytes. For PUSH1 (0x60): skip 1. For PUSH32 (0x7F): skip 32.

These are equivalent.

**Recommendation:** The composition pattern is clean and the fuzz testing is strong. No change needed, but consider documenting the critical dependency on the reachability scanner's correctness in the library NatDoc.

---

## Summary

| ID | Severity | Title |
|---|---|---|
| A04-1 | INFO | SELFDESTRUCT deprecated post-Dencun but still flagged |
| A04-2 | INFO | Over-approximation by design (false positives, no false negatives) |
| A04-3 | INFO | CALL not flagged -- known design tradeoff |
| A04-4 | INFO | EOF bytecode correctly rejected |
| A04-5 | INFO | Empty bytecode handled correctly |
| A04-6 | INFO | Single-byte bytecode edge case handled correctly |
| A04-7 | INFO | METAMORPHIC_OPS bitmap is complete for the threat model |
| A04-8 | INFO | Revert error encoding is correct and informative |
| A04-9 | LOW | Relies entirely on downstream scanner correctness (mitigated by fuzz testing) |

**No CRITICAL, HIGH, or MEDIUM findings identified.**

The library is a thin, well-composed wrapper around `LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode` with a focused `METAMORPHIC_OPS` mask. The code is minimal (33 lines including comments), reducing the attack surface. EOF is rejected. Empty and edge-case inputs are handled correctly. The error is informative. The design is sound.
