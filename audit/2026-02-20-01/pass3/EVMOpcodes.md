# Pass 3: Documentation — A06 — EVMOpcodes

## Evidence of Thorough Reading

**File:** `src/lib/EVMOpcodes.sol`

149 individual `uint8` opcode constants (lines 12–182). 2 `uint256` bitmap constants: `HALTING_BITMAP` (189–194), `METAMORPHIC_OPS` (206–210).

File-level NatSpec (lines 5–10): present and accurate. `HALTING_BITMAP` NatSpec (184–187): accurate, lists all 6 members. `METAMORPHIC_OPS` NatSpec (196–204): accurate, lists all 5 members with rationale.

All opcode values verified against EVM Yellow Paper and relevant EIPs through Cancun.

## Findings

### A06-1: `EVM_OP_DIFFICULTY` uses the pre-Merge opcode name — **INFO**

Line 71: EIP-4399 renamed `0x44` to `PREVRANDAO` at The Merge. Value is correct; no functional bug.

### A06-2: `HALTING_BITMAP` NatSpec does not explicitly state `JUMPI` is excluded — **INFO**

Implicit exclusion via "unconditional JUMP" is adequate but an explicit exclusion note would improve clarity.

### A06-3: Cosmetic inconsistency in shift casting between bitmaps — **INFO**

`HALTING_BITMAP` uses `(1 << EVM_OP_X)` while `METAMORPHIC_OPS` uses `(1 << uint256(EVM_OP_X))`. Both are correct in constant expressions.
