# A01 -- Documentation Audit: EVMOpcodes.sol

**Auditor:** A01
**Date:** 2026-02-20
**Source:** `src/lib/EVMOpcodes.sol`

---

## Findings

### A01-1 | LOW | NON_STATIC_OPS NatSpec does not enumerate all member opcodes

HALTING_BITMAP and METAMORPHIC_OPS enumerate their members in NatSpec. NON_STATIC_OPS does not — a reader must parse the implementation to determine the 11 members (CREATE, CREATE2, LOG0-LOG4, SSTORE, SELFDESTRUCT, CALL, TSTORE).
