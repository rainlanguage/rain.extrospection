# Pass 2: Test Coverage — A06 — EVMOpcodes

## Evidence of Thorough Reading

### Source File: `src/lib/EVMOpcodes.sol` (211 lines)

84 individual `uint8` opcode constants. 2 derived `uint256` bitmap constants: `HALTING_BITMAP` (6 bits), `METAMORPHIC_OPS` (5 bits). No functions or errors.

### Test File: `test/src/lib/EVMOpcodes.t.sol` (378 lines)

| Test | Purpose |
|------|---------|
| `testOpcodeValues` | `assertEq` for all 84 opcode constants against raw hex |
| `testHaltingBitmap` | Full numeric cross-check |
| `testHaltingBitmapPopcount` | `ctpop == 6` |
| `testHaltingBitmapIndividualBits` | 6 per-bit inclusion checks |

### Supplementary Coverage

`METAMORPHIC_OPS` tests in `test/src/interface/IExtrospectMetamorphicV1.t.sol`: popcount (5), raw value cross-check, 5 individual bits, 3 exclusion checks.

## Findings

### A06-1: No exclusion tests for `HALTING_BITMAP` — **LOW**

Per-bit inclusion tests exist but no test proves security-sensitive opcodes are absent. Highest-risk omission: `JUMPI` (0x57) is one byte after `JUMP` (0x56, which IS included). A typo inserting JUMPI would suppress reachability scanning past conditional branches. `JUMPDEST` (0x5B) is another high-value exclusion.

### A06-2: `METAMORPHIC_OPS` not imported or exercised in `EVMOpcodes.t.sol` — **INFO**

Tests reside in `IExtrospectMetamorphicV1.t.sol`. Coverage exists but a reader auditing only `EVMOpcodes.t.sol` would not see it.

### A06-3: `METAMORPHIC_OPS` exclusion tests cover 3 of 5 non-member opcodes in `0xF0–0xFF` — **INFO**

STATICCALL, CALL, RETURN checked absent. REVERT and INVALID not checked. Popcount provides indirect protection.
