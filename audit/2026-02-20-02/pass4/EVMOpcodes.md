# A01 -- Code Quality Audit: EVMOpcodes.sol

**Auditor:** A01
**Date:** 2026-02-20
**Source:** `src/lib/EVMOpcodes.sol`

---

## Findings

### A01-1 | LOW | Inconsistent `uint256()` casting in bitmap shift expressions

HALTING_BITMAP uses bare `(1 << EVM_OP_X)` without explicit uint256 casts. All three other bitmaps use explicit `(1 << uint256(EVM_OP_X))`. Both are semantically identical but the style is inconsistent within the file.

### A01-2 | LOW | `NON_STATIC_OPS` NatSpec does not enumerate all member opcodes

Duplicate of Pass 3 A01-1. Other bitmaps enumerate their members; NON_STATIC_OPS does not.

### A01-3 | LOW | `forge-lint` annotation density is high and repetitive

13 instances of `//forge-lint: disable-next-line(incorrect-shift)` across the four bitmap definitions. Necessary but degrades readability. Inherent limitation of line-granularity lint suppression.
