# A01 Pass 3 (Documentation): `src/interface/IExtrospectBytecodeV2.sol`

## Evidence of Thorough Reading

### Interface Name
- `IExtrospectBytecodeV2` (line 11)

### Functions (all `external view`)
| Function | Line | Parameters | Return Type |
|----------|------|------------|-------------|
| `bytecode` | 19 | `address account` | `bytes memory` |
| `bytecodeHash` | 28 | `address account` | `bytes32` |
| `scanEVMOpcodesPresentInAccount` | 58 | `address account` | `uint256 scan` |
| `scanEVMOpcodesReachableInAccount` | 72 | `address account` | `uint256 scan` |

### Types, Errors, Constants
None. Pure interface.

## NatSpec Coverage

- Interface-level: `@title` (line 5), `@notice` (lines 6-10). Accurate.
- `bytecode`: Description, `@param`, `@return` all present. Accurate.
- `bytecodeHash`: Description, `@param`, `@return` all present. See A01-P3-1.
- `scanEVMOpcodesPresentInAccount`: Extensive docs (lines 30-56), `@param`, `@return`. Thorough.
- `scanEVMOpcodesReachableInAccount`: Description (lines 60-67), `@param`, `@return`. Accurate.

## Findings

### A01-P3-1 [LOW] `bytecodeHash` documentation inaccurately describes behavior for non-contract accounts

**Lines 26-27:** The `@return` states: "Will be `0` (NOT the hash of empty bytes) for non-contract accounts." This conflates two account states per EIP-1052:
1. Non-existent accounts (never touched): `EXTCODEHASH` returns `0`. Correct.
2. EOAs with balance/nonce: `EXTCODEHASH` returns `keccak256("")`. Incorrect — documentation says `0`.

The parenthetical "(NOT the hash of empty bytes)" is specifically wrong for funded EOAs.

### A01-P3-2 [INFO] No V1-to-V2 migration documentation

The interface does not document what changed from V1 to V2 or why V2 exists.

### A01-P3-3 [INFO] Typo "prescence" on line 43

Should be "presence".

### A01-P3-4 [INFO] Inconsistent named vs unnamed return parameters

`bytecode` and `bytecodeHash` use anonymous returns; scan functions use named returns (`uint256 scan`).
