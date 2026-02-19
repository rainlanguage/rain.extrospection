# A06 Pass 4 (Code Quality): `src/lib/LibExtrospectBytecode.sol`

## Evidence of Thorough Reading

- Library: `LibExtrospectBytecode` (line 12)
- Errors: `MetadataNotTrimmed` (16), `EOFBytecodeNotSupported` (19), `BytecodeHashMismatch` (24)
- Functions: `isEOFBytecode` (29), `checkNotEOFBytecode` (41), `tryTrimSolidityCBORMetadata` (90), `checkCBORTrimmedBytecodeHash` (117), `scanEVMOpcodesReachableInBytecode` (135), `scanEVMOpcodesPresentInBytecode` (190)

## Findings

### A06-P4-1 [LOW] Code duplication between the two scan functions

Lines 135-179 and 190-211 share: EOF check, pointer setup, cursor alignment, loop structure, opcode extraction, bitmap OR, PUSH skip logic. The "Reachable" variant adds halting/JUMPDEST tracking. Duplication is defensible for assembly performance, but updating one without the other risks drift. A cross-referencing comment would help.

### A06-P4-2 [INFO] Minor ordering difference in PUSH skip vs opcode recording

`scanEVMOpcodesReachableInBytecode`: PUSH skip before halted-state switch. `scanEVMOpcodesPresentInBytecode`: PUSH skip after opcode recording. Both correct, but inconsistent ordering between related functions.

### A06-P4-3 [INFO] `checkCBORTrimmedBytecodeHash` uses explicit `LibExtrospectBytecode.` prefix for internal call

Line 119: `LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode)` — other internal calls (e.g., `checkNotEOFBytecode`) don't use the prefix.

### A06-P4-4 [INFO] Foundry config disables metadata but library contains metadata trimming

`bytecode_hash = "none"` and `cbor_metadata = false` in foundry.toml. Library trims metadata from external contracts. Not a defect — library processes third-party bytecode.

### A06-P4-5 [INFO] Scratch space usage in `tryTrimSolidityCBORMetadata` is correct

Memory 0x00-0x3F used for temporary keccak256. Properly marked `"memory-safe"`.

### A06-P4-6 [INFO] Assembly variable naming and readability — good quality

### A06-P4-7 [INFO] Function ordering is logical (building blocks first, composed functions later)

### A06-P4-8 [INFO] No commented-out code

### A06-P4-9 [INFO] Style consistency with sibling library — consistent

### A06-P4-10 [LOW] Stale NatSpec comment referencing `extcodecopy`

Lines 181-184: NatSpec for `scanEVMOpcodesPresentInBytecode` describes memory cursor setup and `extcodecopy` pattern, but the function takes `bytes memory bytecode`. Vestige of an older API.
