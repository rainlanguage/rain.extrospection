# A02 - Test Coverage Audit: LibExtrospectBytecode

**Auditor:** A02
**Date:** 2026-02-20
**Source:** `src/lib/LibExtrospectBytecode.sol`

---

## Source File Inventory

**Library:** `LibExtrospectBytecode`

### Errors

| Error | Line |
|---|---|
| `MetadataNotTrimmed()` | 16 |
| `EOFBytecodeNotSupported()` | 19 |
| `BytecodeHashMismatch(bytes32 expected, bytes32 actual)` | 24 |
| `UnexpectedMetadata()` | 29 |

### Functions

| Function | Line |
|---|---|
| `isEOFBytecode` | 34 |
| `checkNotEOFBytecode` | 46 |
| `tryTrimSolidityCBORMetadata` | 96 |
| `checkCBORTrimmedBytecodeHash` | 123 |
| `checkNoSolidityCBORMetadata` | 142 |
| `scanEVMOpcodesReachableInBytecode` | 165 |
| `scanEVMOpcodesPresentInBytecode` | 218 |

---

## Findings

### A02-1 | LOW | No fuzz test for `checkCBORTrimmedBytecodeHash`

Tested only with hardcoded production addresses via fork tests. No fuzz test with arbitrary bytecode/hash combinations. `BytecodeHashMismatch` error path tested with only one hardcoded incorrect hash.

### A02-2 | LOW | No fuzz test for `checkNoSolidityCBORMetadata`

Tested with exactly three scenarios (empty account, clean contract, etched metadata). No fuzz test with arbitrary bytecode.

### A02-3 | LOW | `isEOFBytecode` does not test exact 2-byte `0xEF00` input

Tests exercise empty, single byte `0xEF`, non-EOF multi-byte, and EOF with trailing bytes. Missing the minimum valid EOF detection case (exactly 2 bytes `hex"EF00"`).

### A02-4 | LOW | `tryTrimSolidityCBORMetadata` not tested with bytecode length exactly 52

The function checks `length >= 53`. The off-by-one boundary at 52 bytes has no explicit concrete test.

### A02-5 | LOW | `checkNotEOFBytecode` non-revert path tested with only one concrete input

Only `hex"6001600055"` tested for the non-revert path.

### A02-6 | LOW | `checkCBORTrimmedBytecodeHash` and `checkNoSolidityCBORMetadata` EOF revert paths not explicitly tested

Both internally call `tryTrimSolidityCBORMetadata` which calls `checkNotEOFBytecode`. No test calls either wrapper with EOF-bytecode account.

### A02-7 | MEDIUM | No test demonstrating false-negative behavior on non-standard CBOR metadata

Documentation warns of false negatives on non-standard metadata. No test validates this claim with alternative metadata structures (bzzr1 Swarm hash, different key ordering, etc.).

### A02-8 | MEDIUM | `tryTrimSolidityCBORMetadata` mask/hash correctness not independently validated

The hardcoded `expectedHash` (line 104) and two masks are not independently reconstructed in any test from known static CBOR bytes. If wrong, the function would silently fail to trim valid metadata.
