# Pass 4: Code Quality — A09 — LibExtrospectMetamorphic

## Evidence of Thorough Reading

**File:** `src/lib/LibExtrospectMetamorphic.sol` (33 lines)

**Library:** `LibExtrospectMetamorphic` (line 8)

**Error:** `Metamorphic(uint256 riskyOpcodes)` (line 15)

**Functions (2):** `scanMetamorphicRisk` (17), `checkNotMetamorphic` (25)

No assembly, no `unchecked`, no commented-out code, no lint suppressions.

## Findings

### A09-1: `Metamorphic` error declared in library but absent from the external interface — **LOW**

`checkNotMetamorphic` reverts with `Metamorphic(uint256)` declared at line 15 inside `LibExtrospectMetamorphic`. The external interface `IExtrospectMetamorphicV1` does not declare this error, so ABI consumers cannot decode the revert data without importing the library directly. The same pattern exists in `LibExtrospectBytecode` (errors are library-local), so this is project-wide consistency but remains a leaky abstraction.

### A09-2: `checkNotMetamorphic` NatSpec does not document the transitive EOF revert path — **INFO**

The function transitively reverts with `EOFBytecodeNotSupported` for EOF-formatted input (via `scanMetamorphicRisk` -> `scanEVMOpcodesReachableInBytecode` -> `checkNotEOFBytecode`). This secondary revert condition is undocumented. By contrast, `tryTrimSolidityCBORMetadata` in `LibExtrospectBytecode.sol` explicitly notes the EOF revert.
