# Pass 4: Code Quality — A07 — LibExtrospectBytecode

## Evidence of Thorough Reading

**File:** `src/lib/LibExtrospectBytecode.sol`
**Library:** `LibExtrospectBytecode` (line 12)

**Errors (4):** `MetadataNotTrimmed` (16), `EOFBytecodeNotSupported` (19), `BytecodeHashMismatch` (24), `UnexpectedMetadata` (29)

**Functions (7):** `isEOFBytecode` (34), `checkNotEOFBytecode` (46), `tryTrimSolidityCBORMetadata` (96), `checkCBORTrimmedBytecodeHash` (123), `checkNoSolidityCBORMetadata` (142), `scanEVMOpcodesReachableInBytecode` (156), `scanEVMOpcodesPresentInBytecode` (209)

**Assembly blocks (4):** all annotated `"memory-safe"`.

## Findings

### A07-1: Inconsistent PUSH-skip block style between the two scan functions — **INFO**

`scanEVMOpcodesReachableInBytecode` (lines 174–176) uses a multi-line braced block for the PUSH-skip `if`. `scanEVMOpcodesPresentInBytecode` (line 227) uses an inline single-line form for structurally identical logic.

### A07-2: Operation ordering inside the two scan functions diverges — **INFO**

In `scanEVMOpcodesPresentInBytecode` the loop body records the opcode first, then skips PUSH data. In `scanEVMOpcodesReachableInBytecode` the PUSH-skip executes before the `switch` that records the opcode. Both orderings are correct but the divergence makes the two functions harder to compare.

### A07-3: `tryTrimSolidityCBORMetadata` writes to scratch space without an explanatory comment — **INFO**

Lines 109–111 use scratch space (0x00–0x3f) for keccak256. Valid under Solidity memory layout rules but no inline comment explains why scratch space is used.

### A07-4: `checkCBORTrimmedBytecodeHash` and `checkNoSolidityCBORMetadata` qualify the callee with the library name unnecessarily — **INFO**

Lines 125 and 144 use `LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode)` while all other internal calls are unqualified.

### A07-5: `scanEVMOpcodesReachableInBytecode` copies constants to named stack variables with no explanatory comment — **INFO**

Lines 161–162 copy file-level constants to local variables for assembly access. The idiom is necessary but unexplained.

### A07-6: `expectedHash` in `tryTrimSolidityCBORMetadata` uses an unnecessary double cast — **INFO**

Line 104: `bytes32(uint256(0x0e55...))` — the literal fits in 32 bytes and can be written as a direct `bytes32` assignment.

### A07-7: Unreachable `default` branch uses empty `revert(0, 0)` inconsistent with the library's typed-error pattern — **INFO**

Lines 196–197: Every other revert path uses a named typed error. The empty revert is intentionally unreachable but inconsistent with the library's error-handling style.
