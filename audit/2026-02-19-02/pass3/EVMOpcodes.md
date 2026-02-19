# A05 Pass 3 (Documentation): `src/lib/EVMOpcodes.sol`

## Evidence of Thorough Reading

File contains 135 `uint8` opcode constants (lines 5-175) and 1 `uint256` derived constant `HALTING_BITMAP` (lines 178-183). Total: 136 constants. Current through Cancun hard fork.

Key constants verified:
- `EVM_OP_STOP` = 0x00 (line 5) through `EVM_OP_SELFDESTRUCT` = 0xFF (line 175)
- `HALTING_BITMAP` composed of STOP, RETURN, REVERT, INVALID, SELFDESTRUCT, JUMP
- Cancun additions: BLOBHASH (0x49), BLOBBASEFEE (0x4A), TLOAD (0x5C), TSTORE (0x5D), MCOPY (0x5E)

### Documentation Present
- Zero NatSpec comments (`///`, `/** */`) in entire file
- Zero `@title`, `@notice`, `@dev`, or `@param` tags
- Only comments: 3 forge-lint suppressions and 1 inline comment on JUMP halting (line 181)

## Findings

### A05-P3-1 [LOW] No file-level documentation

The file has zero NatSpec. No `@title`, `@notice`, or `@dev`. For a 136-constant foundational dependency used across the library, the absence of any documentation describing purpose, scope, or EVM version coverage is a gap.

### A05-P3-2 [LOW] `HALTING_BITMAP` lacks NatSpec documentation

Lines 177-183: Only a single inline comment on JUMP. Missing: overall purpose, complete member list with rationale, why JUMPI is excluded, consumer reference (`scanEVMOpcodesReachableInBytecode`).

### A05-P3-3 [INFO] `EVM_OP_DIFFICULTY` name outdated post-Merge

Line 64: Opcode 0x44 renamed to PREVRANDAO by EIP-4399. No comment noting semantic change.

### A05-P3-4 [INFO] No group-level comments for opcode categories

The 135 constants are visually grouped by blank lines but no category headers.

### A05-P3-5 [INFO] `EVM_OP_SELFDESTRUCT` has no post-Dencun semantic change note

Line 175: Post-EIP-6780, SELFDESTRUCT only destroys contracts created in same transaction.

### A05-P3-6 [INFO] forge-lint suppressions lack explanatory comments

Lines 177, 179, 182: Three `incorrect-shift` suppressions with no explanation.
