# A05 Pass 4 (Code Quality): `src/lib/EVMOpcodes.sol`

## Evidence of Thorough Reading

136 constants total: 135 `uint8` opcode constants (lines 5-175) + 1 `uint256` `HALTING_BITMAP` (lines 178-183). Current through Cancun. All values verified correct.

Only used in production: `EVM_OP_JUMPDEST`, `HALTING_BITMAP` (by `LibExtrospectBytecode.sol`), and 15 opcodes (by `IExtrospectInterpreterV1.sol`). ~113 constants never referenced outside the file.

## Findings

### A05-P4-1 [INFO] `EVM_OP_DIFFICULTY` naming outdated post-Merge

Opcode 0x44 renamed to PREVRANDAO by EIP-4399. Not referenced outside the file.

### A05-P4-2 [INFO] Large number of unused constants

~113 of 135 constants never imported. Intentional comprehensive reference library pattern. No deployment cost when not imported.

### A05-P4-3 [INFO] Minor blank-line grouping inconsistency at line 59

`EXTCODEHASH` (0x3F) and `BLOCKHASH` (0x40) on consecutive lines without separator despite being different semantic groups.

### A05-P4-4 [INFO] No NatSpec or file-level documentation

No `@title`, `@notice`, or `@dev` tags anywhere in the file.

### A05-P4-5 [INFO] `HALTING_BITMAP` lacks NatSpec documentation

Only inline comment about JUMP. No overall purpose/member documentation.

### A05-P4-6 [LOW] `pragma solidity ^0.8.18` broader than configured compiler

Project pins `solc = "0.8.25"` but pragma allows `^0.8.18`. Consistent across all source files. Low risk since constants are just numeric values.
