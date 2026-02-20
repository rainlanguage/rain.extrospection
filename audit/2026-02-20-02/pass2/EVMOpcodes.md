# A01 -- Test Coverage Audit: EVMOpcodes.sol

**Auditor:** A01
**Date:** 2026-02-20
**Source:** `src/lib/EVMOpcodes.sol`

---

## Findings

### A01-1 | LOW | METAMORPHIC_OPS subset/superset relationship to other bitmaps not explicitly tested

`testInterpreterDisallowedOpsIsSupersetOfNonStaticOps()` verifies INTERPRETER_DISALLOWED_OPS is a strict superset of NON_STATIC_OPS. No analogous test verifies the relationship between METAMORPHIC_OPS and the other bitmaps. An explicit test asserting `METAMORPHIC_OPS & INTERPRETER_DISALLOWED_OPS == METAMORPHIC_OPS` would codify the security invariant.

### A01-2 | LOW | HALTING_BITMAP relationship to METAMORPHIC_OPS not explicitly tested

Both include SELFDESTRUCT. No test verifies their overlap is exactly {SELFDESTRUCT}.
