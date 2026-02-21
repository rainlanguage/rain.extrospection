# A04 -- Code Quality Audit: LibExtrospectMetamorphic.sol

**Auditor:** A04
**Date:** 2026-02-20
**Source:** `src/lib/LibExtrospectMetamorphic.sol`

---

## Findings

### A04-1 | LOW | `Metamorphic` error declared only in library, not in any external interface

ABI consumers cannot decode the revert reason without importing the library directly. This is consistent with `LibExtrospectBytecode` which also declares errors locally, but is a minor integration friction for downstream consumers.

### A04-2 | LOW | Missing NatSpec for transitive EOF revert path

Neither `scanMetamorphicRisk` nor `checkNotMetamorphic` documents that EOF bytecode triggers `EOFBytecodeNotSupported` (from the transitive call to `scanEVMOpcodesReachableInBytecode`). Other functions in LibExtrospectBytecode document this revert condition explicitly.
