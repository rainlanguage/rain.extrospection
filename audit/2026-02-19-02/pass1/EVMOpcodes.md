# Pass 1: EVMOpcodes.sol Security Audit

**Auditor:** A05
**File:** `src/lib/EVMOpcodes.sol` (184 lines)

## Evidence of Thorough Reading

### Library/Contract Name

This file does not define a library or contract. It defines file-level (`constant`) declarations only, intended for import by other Solidity files.

### Functions

No functions are defined in this file.

### Types and Errors

No types or errors are defined in this file.

### Constants Defined

All constants are `uint8` unless otherwise noted.

| Line | Name | Value |
|------|------|-------|
| 5 | `EVM_OP_STOP` | `0x00` |
| 7 | `EVM_OP_ADD` | `0x01` |
| 8 | `EVM_OP_MUL` | `0x02` |
| 9 | `EVM_OP_SUB` | `0x03` |
| 10 | `EVM_OP_DIV` | `0x04` |
| 11 | `EVM_OP_SDIV` | `0x05` |
| 12 | `EVM_OP_MOD` | `0x06` |
| 13 | `EVM_OP_SMOD` | `0x07` |
| 14 | `EVM_OP_ADDMOD` | `0x08` |
| 15 | `EVM_OP_MULMOD` | `0x09` |
| 16 | `EVM_OP_EXP` | `0x0A` |
| 17 | `EVM_OP_SIGNEXTEND` | `0x0B` |
| 19 | `EVM_OP_LT` | `0x10` |
| 20 | `EVM_OP_GT` | `0x11` |
| 21 | `EVM_OP_SLT` | `0x12` |
| 22 | `EVM_OP_SGT` | `0x13` |
| 23 | `EVM_OP_EQ` | `0x14` |
| 24 | `EVM_OP_ISZERO` | `0x15` |
| 26 | `EVM_OP_AND` | `0x16` |
| 27 | `EVM_OP_OR` | `0x17` |
| 28 | `EVM_OP_XOR` | `0x18` |
| 29 | `EVM_OP_NOT` | `0x19` |
| 30 | `EVM_OP_BYTE` | `0x1A` |
| 31 | `EVM_OP_SHL` | `0x1B` |
| 32 | `EVM_OP_SHR` | `0x1C` |
| 33 | `EVM_OP_SAR` | `0x1D` |
| 35 | `EVM_OP_SHA3` | `0x20` |
| 37 | `EVM_OP_ADDRESS` | `0x30` |
| 38 | `EVM_OP_BALANCE` | `0x31` |
| 40 | `EVM_OP_ORIGIN` | `0x32` |
| 41 | `EVM_OP_CALLER` | `0x33` |
| 42 | `EVM_OP_CALLVALUE` | `0x34` |
| 43 | `EVM_OP_CALLDATALOAD` | `0x35` |
| 44 | `EVM_OP_CALLDATASIZE` | `0x36` |
| 45 | `EVM_OP_CALLDATACOPY` | `0x37` |
| 47 | `EVM_OP_CODESIZE` | `0x38` |
| 48 | `EVM_OP_CODECOPY` | `0x39` |
| 50 | `EVM_OP_GASPRICE` | `0x3A` |
| 52 | `EVM_OP_EXTCODESIZE` | `0x3B` |
| 53 | `EVM_OP_EXTCODECOPY` | `0x3C` |
| 55 | `EVM_OP_RETURNDATASIZE` | `0x3D` |
| 56 | `EVM_OP_RETURNDATACOPY` | `0x3E` |
| 58 | `EVM_OP_EXTCODEHASH` | `0x3F` |
| 59 | `EVM_OP_BLOCKHASH` | `0x40` |
| 61 | `EVM_OP_COINBASE` | `0x41` |
| 62 | `EVM_OP_TIMESTAMP` | `0x42` |
| 63 | `EVM_OP_NUMBER` | `0x43` |
| 64 | `EVM_OP_DIFFICULTY` | `0x44` |
| 65 | `EVM_OP_GASLIMIT` | `0x45` |
| 66 | `EVM_OP_CHAINID` | `0x46` |
| 68 | `EVM_OP_SELFBALANCE` | `0x47` |
| 70 | `EVM_OP_BASEFEE` | `0x48` |
| 71 | `EVM_OP_BLOBHASH` | `0x49` |
| 72 | `EVM_OP_BLOBBASEFEE` | `0x4A` |
| 74 | `EVM_OP_POP` | `0x50` |
| 75 | `EVM_OP_MLOAD` | `0x51` |
| 76 | `EVM_OP_MSTORE` | `0x52` |
| 77 | `EVM_OP_MSTORE8` | `0x53` |
| 79 | `EVM_OP_SLOAD` | `0x54` |
| 80 | `EVM_OP_SSTORE` | `0x55` |
| 82 | `EVM_OP_JUMP` | `0x56` |
| 83 | `EVM_OP_JUMPI` | `0x57` |
| 84 | `EVM_OP_PC` | `0x58` |
| 85 | `EVM_OP_MSIZE` | `0x59` |
| 86 | `EVM_OP_GAS` | `0x5A` |
| 87 | `EVM_OP_JUMPDEST` | `0x5B` |
| 88 | `EVM_OP_TLOAD` | `0x5C` |
| 89 | `EVM_OP_TSTORE` | `0x5D` |
| 90 | `EVM_OP_MCOPY` | `0x5E` |
| 92 | `EVM_OP_PUSH0` | `0x5F` |
| 93 | `EVM_OP_PUSH1` | `0x60` |
| 94 | `EVM_OP_PUSH2` | `0x61` |
| 95 | `EVM_OP_PUSH3` | `0x62` |
| 96 | `EVM_OP_PUSH4` | `0x63` |
| 97 | `EVM_OP_PUSH5` | `0x64` |
| 98 | `EVM_OP_PUSH6` | `0x65` |
| 99 | `EVM_OP_PUSH7` | `0x66` |
| 100 | `EVM_OP_PUSH8` | `0x67` |
| 101 | `EVM_OP_PUSH9` | `0x68` |
| 102 | `EVM_OP_PUSH10` | `0x69` |
| 103 | `EVM_OP_PUSH11` | `0x6A` |
| 104 | `EVM_OP_PUSH12` | `0x6B` |
| 105 | `EVM_OP_PUSH13` | `0x6C` |
| 106 | `EVM_OP_PUSH14` | `0x6D` |
| 107 | `EVM_OP_PUSH15` | `0x6E` |
| 108 | `EVM_OP_PUSH16` | `0x6F` |
| 109 | `EVM_OP_PUSH17` | `0x70` |
| 110 | `EVM_OP_PUSH18` | `0x71` |
| 111 | `EVM_OP_PUSH19` | `0x72` |
| 112 | `EVM_OP_PUSH20` | `0x73` |
| 113 | `EVM_OP_PUSH21` | `0x74` |
| 114 | `EVM_OP_PUSH22` | `0x75` |
| 115 | `EVM_OP_PUSH23` | `0x76` |
| 116 | `EVM_OP_PUSH24` | `0x77` |
| 117 | `EVM_OP_PUSH25` | `0x78` |
| 118 | `EVM_OP_PUSH26` | `0x79` |
| 119 | `EVM_OP_PUSH27` | `0x7A` |
| 120 | `EVM_OP_PUSH28` | `0x7B` |
| 121 | `EVM_OP_PUSH29` | `0x7C` |
| 122 | `EVM_OP_PUSH30` | `0x7D` |
| 123 | `EVM_OP_PUSH31` | `0x7E` |
| 124 | `EVM_OP_PUSH32` | `0x7F` |
| 126 | `EVM_OP_DUP1` | `0x80` |
| 127 | `EVM_OP_DUP2` | `0x81` |
| 128 | `EVM_OP_DUP3` | `0x82` |
| 129 | `EVM_OP_DUP4` | `0x83` |
| 130 | `EVM_OP_DUP5` | `0x84` |
| 131 | `EVM_OP_DUP6` | `0x85` |
| 132 | `EVM_OP_DUP7` | `0x86` |
| 133 | `EVM_OP_DUP8` | `0x87` |
| 134 | `EVM_OP_DUP9` | `0x88` |
| 135 | `EVM_OP_DUP10` | `0x89` |
| 136 | `EVM_OP_DUP11` | `0x8A` |
| 137 | `EVM_OP_DUP12` | `0x8B` |
| 138 | `EVM_OP_DUP13` | `0x8C` |
| 139 | `EVM_OP_DUP14` | `0x8D` |
| 140 | `EVM_OP_DUP15` | `0x8E` |
| 141 | `EVM_OP_DUP16` | `0x8F` |
| 143 | `EVM_OP_SWAP1` | `0x90` |
| 144 | `EVM_OP_SWAP2` | `0x91` |
| 145 | `EVM_OP_SWAP3` | `0x92` |
| 146 | `EVM_OP_SWAP4` | `0x93` |
| 147 | `EVM_OP_SWAP5` | `0x94` |
| 148 | `EVM_OP_SWAP6` | `0x95` |
| 149 | `EVM_OP_SWAP7` | `0x96` |
| 150 | `EVM_OP_SWAP8` | `0x97` |
| 151 | `EVM_OP_SWAP9` | `0x98` |
| 152 | `EVM_OP_SWAP10` | `0x99` |
| 153 | `EVM_OP_SWAP11` | `0x9A` |
| 154 | `EVM_OP_SWAP12` | `0x9B` |
| 155 | `EVM_OP_SWAP13` | `0x9C` |
| 156 | `EVM_OP_SWAP14` | `0x9D` |
| 157 | `EVM_OP_SWAP15` | `0x9E` |
| 158 | `EVM_OP_SWAP16` | `0x9F` |
| 160 | `EVM_OP_LOG0` | `0xA0` |
| 161 | `EVM_OP_LOG1` | `0xA1` |
| 162 | `EVM_OP_LOG2` | `0xA2` |
| 163 | `EVM_OP_LOG3` | `0xA3` |
| 164 | `EVM_OP_LOG4` | `0xA4` |
| 166 | `EVM_OP_CREATE` | `0xF0` |
| 167 | `EVM_OP_CALL` | `0xF1` |
| 168 | `EVM_OP_CALLCODE` | `0xF2` |
| 169 | `EVM_OP_RETURN` | `0xF3` |
| 170 | `EVM_OP_DELEGATECALL` | `0xF4` |
| 171 | `EVM_OP_CREATE2` | `0xF5` |
| 172 | `EVM_OP_STATICCALL` | `0xFA` |
| 173 | `EVM_OP_REVERT` | `0xFD` |
| 174 | `EVM_OP_INVALID` | `0xFE` |
| 175 | `EVM_OP_SELFDESTRUCT` | `0xFF` |

**Derived constant (type `uint256`):**

| Line | Name | Construction |
|------|------|-------------|
| 178-183 | `HALTING_BITMAP` | `(1 << EVM_OP_STOP) \| (1 << EVM_OP_RETURN) \| (1 << EVM_OP_REVERT) \| (1 << EVM_OP_INVALID) \| (1 << EVM_OP_SELFDESTRUCT) \| (1 << EVM_OP_JUMP)` |

**Total constants:** 142 (`uint8`) + 1 (`uint256`) = 143

## Cross-Reference Against Canonical EVM Specification

All 141 named EVM opcodes defined in this file were cross-referenced against the canonical Ethereum Yellow Paper and evm.codes opcode table. Every opcode value matches its canonical assignment:

- **0x00-0x0B (Arithmetic):** All 12 opcodes correct.
- **0x10-0x15 (Comparison):** All 6 opcodes correct.
- **0x16-0x1D (Bitwise):** All 8 opcodes correct.
- **0x20 (SHA3/KECCAK256):** Correct.
- **0x30-0x3F (Environment):** All 16 opcodes correct.
- **0x40-0x4A (Block):** All 11 opcodes correct, including post-EIP-4844 BLOBHASH (0x49) and EIP-7516 BLOBBASEFEE (0x4A).
- **0x50-0x5E (Stack/Memory/Storage/Flow):** All 15 opcodes correct, including EIP-1153 TLOAD/TSTORE and EIP-5656 MCOPY.
- **0x5F-0x7F (PUSH0-PUSH32):** All 33 opcodes correct.
- **0x80-0x8F (DUP1-DUP16):** All 16 opcodes correct.
- **0x90-0x9F (SWAP1-SWAP16):** All 16 opcodes correct.
- **0xA0-0xA4 (LOG0-LOG4):** All 5 opcodes correct.
- **0xF0-0xFF (System):** All 10 opcodes correct.

## HALTING_BITMAP Verification

The `HALTING_BITMAP` includes the following opcodes:

| Opcode | Value | Bit Position | Halts Execution? |
|--------|-------|-------------|------------------|
| STOP | 0x00 | 0 | Yes -- terminates execution |
| RETURN | 0xF3 | 243 | Yes -- terminates execution, returns data |
| REVERT | 0xFD | 253 | Yes -- terminates execution, reverts state |
| INVALID | 0xFE | 254 | Yes -- terminates execution, consumes all gas |
| SELFDESTRUCT | 0xFF | 255 | Yes -- terminates execution (still halts post-Dencun EIP-6780) |
| JUMP | 0x56 | 86 | Yes (design choice) -- unconditional jump cannot fall through |

All bit positions are within the valid range for `uint256` (0-255). The shift arithmetic is correct.

**Verification of completeness:** The five EVM opcodes that truly terminate execution of the current call frame are STOP, RETURN, REVERT, INVALID, and SELFDESTRUCT. All five are included. JUMP is included as a design decision for the reachability scanner (code after an unconditional JUMP is unreachable unless preceded by a JUMPDEST target). JUMPI is correctly excluded since conditional jumps can fall through.

## Findings

### A05-1 [INFO] `DIFFICULTY` constant not aliased to `PREVRANDAO`

**File:** `src/lib/EVMOpcodes.sol`, line 64

Since the Ethereum merge (Paris upgrade, September 2022), opcode 0x44 returns the PREVRANDAO value rather than the mining difficulty. The constant is still named `EVM_OP_DIFFICULTY`, which is the pre-merge name. While the opcode number (0x44) is correct regardless of naming, the lack of an `EVM_OP_PREVRANDAO` alias may cause confusion for developers using this library in a post-merge context. Solidity itself added the `block.prevrandao` alias in 0.8.18.

No functional impact, as the opcode value is correct and the constant is not currently referenced by any code in this repository.

### A05-2 [INFO] No constants defined for undefined opcode ranges

**File:** `src/lib/EVMOpcodes.sol`

The file defines constants only for valid/named opcodes. Opcodes in undefined ranges (0x0C-0x0F, 0x1E-0x1F, 0x21-0x2F, 0x4B-0x4F, 0xA5-0xEF, 0xF6-0xF9, 0xFB-0xFC) are not defined. This is standard practice and not a concern for the current usage (bitmap construction and bytecode scanning), but consumers of this library should be aware that not all 256 byte values have corresponding named constants.

No functional impact.

### A05-3 [INFO] SELFDESTRUCT semantics changed post-Dencun but still halts

**File:** `src/lib/EVMOpcodes.sol`, line 175 and line 180

Post-Dencun (EIP-6780), `SELFDESTRUCT` only destroys a contract if called in the same transaction that created it. However, it still terminates execution of the current call context (behaving like STOP after sending ether). Its inclusion in `HALTING_BITMAP` remains correct. This is noted for documentation purposes only.

No functional impact.

## Summary

No security issues were identified. All 141 opcode constants are correctly valued per the canonical EVM specification. The `HALTING_BITMAP` correctly includes all five execution-terminating opcodes (STOP, RETURN, REVERT, INVALID, SELFDESTRUCT) plus JUMP (as a sound design choice for reachability analysis). The bitmap arithmetic is correct with all bit positions within the valid `uint256` range. Three informational notes were raised regarding naming conventions and documentation.
