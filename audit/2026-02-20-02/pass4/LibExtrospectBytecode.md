# A02 -- Code Quality Audit: LibExtrospectBytecode.sol

**Auditor:** A02
**Date:** 2026-02-20
**Source:** `src/lib/LibExtrospectBytecode.sol`

---

## Findings

### A02-1 | LOW | Inconsistent `end` variable declaration between scan functions

`scanEVMOpcodesReachableInBytecode` (line 169) declares `end` as Solidity-level `Pointer end;` then assigns in assembly. `scanEVMOpcodesPresentInBytecode` (line 224) declares `end` as Yul-local `let end`. Style inconsistency between closely related functions.

### A02-2 | LOW | Self-referential qualified calls within the library

Lines 125, 144: `LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode)` uses the fully qualified library name, while other internal calls (lines 47, 97) use the unqualified form.
