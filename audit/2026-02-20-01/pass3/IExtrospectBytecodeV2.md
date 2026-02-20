# Pass 3: Documentation — A01 — IExtrospectBytecodeV2

## Evidence of Thorough Reading

**Interface:** `IExtrospectBytecodeV2` (line 11)

**Functions:**

| Line | Function |
|------|----------|
| 19 | `bytecode(address account) external view returns (bytes memory)` |
| 29 | `bytecodeHash(address account) external view returns (bytes32)` |
| 59 | `scanEVMOpcodesPresentInAccount(address account) external view returns (uint256 scan)` |
| 73 | `scanEVMOpcodesReachableInAccount(address account) external view returns (uint256 scan)` |

All four functions have `@param` and `@return` tags. Header (SPDX, copyright, pragma) present and correct.

## Findings

### A01-1: `scanEVMOpcodesPresentInAccount` missing revert condition for EOF bytecode — **MEDIUM**

The implementation calls `checkNotEOFBytecode` which reverts with `EOFBytecodeNotSupported()` for EOF-formatted bytecode. This revert condition is absent from the interface NatSpec. Callers have no indication this view function can revert.

### A01-2: `scanEVMOpcodesReachableInAccount` missing revert condition for EOF bytecode — **MEDIUM**

Same issue: the reachable scan also calls `checkNotEOFBytecode` and can revert with `EOFBytecodeNotSupported()`. Not documented in the interface NatSpec.

### A01-3: `bytecode` `@return` uses backtick-quoted `0` to describe a zero-length array — **LOW**

Line 17-18: "Will be `0` length for non-contract accounts." — backtick-quoted `0` implies a literal integer, but the return type is `bytes memory`. Should say "empty (zero length)".
