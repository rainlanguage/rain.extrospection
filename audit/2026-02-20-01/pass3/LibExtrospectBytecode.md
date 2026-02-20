# Pass 3: Documentation — A07 — LibExtrospectBytecode

## Evidence of Thorough Reading

**Library:** `LibExtrospectBytecode` (line 12)

**Errors (4):** `MetadataNotTrimmed` (16), `EOFBytecodeNotSupported` (19), `BytecodeHashMismatch` (24), `UnexpectedMetadata` (29) — all have NatSpec.

**Functions (7):** `isEOFBytecode` (34), `checkNotEOFBytecode` (46), `tryTrimSolidityCBORMetadata` (96), `checkCBORTrimmedBytecodeHash` (123), `checkNoSolidityCBORMetadata` (142), `scanEVMOpcodesReachableInBytecode` (156), `scanEVMOpcodesPresentInBytecode` (209) — all have NatSpec with `@param` and `@return` tags.

## Findings

### A07-1: `checkCBORTrimmedBytecodeHash` and `checkNoSolidityCBORMetadata` omit the EOF revert path — **INFO**

Both call `tryTrimSolidityCBORMetadata` which calls `checkNotEOFBytecode`. Neither documents the `EOFBytecodeNotSupported` revert condition.

### A07-2: `scanEVMOpcodesReachableInBytecode` NatSpec does not document the halting-and-resume algorithm — **LOW**

The `@return` states only "each bit represents the presence of a reachable opcode." The halting behavior (STOP/JUMP/RETURN/REVERT/INVALID/SELFDESTRUCT halt scanning, JUMPDEST resumes), the linear over-approximation, and PUSH data-skipping are not documented. A caller cannot understand what "reachable" means from the NatSpec alone.

### A07-3: Both scan functions omit documentation of bit-encoding scheme and PUSH data-skipping — **INFO**

Neither specifies that bit N = opcode 0xN. `scanEVMOpcodesReachableInBytecode` makes no NatSpec mention of PUSH-skip (only an assembly comment). The PUSH-skip is security-critical for JUMPDEST tracking.

### A07-4: CBOR byte `0x43` description inconsistent with `0x58` encoding description — **INFO**

Line 68 describes `0x43` as "cbor byte string prefix (3-byte version follows)" using the same phrasing as `0x58` despite different CBOR encoding strategies. Functionally correct but potentially confusing.
