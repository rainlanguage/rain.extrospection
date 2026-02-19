# A04 Pass 3 (Documentation): `src/interface/deprecated/IExtrospectBytecodeV1.sol`

## Evidence of Thorough Reading

### Interface Name
- `IExtrospectBytecodeV1` (line 11)
- Located in `deprecated/` directory

### Functions (all `external view`)
| Function | Line | Parameters | Return |
|----------|------|------------|--------|
| `bytecode` | 19 | `address account` | `bytes memory` |
| `bytecodeHash` | 28 | `address account` | `bytes32` |
| `scanEVMOpcodesPresentInAccount` | 55 | `address account` | `uint256 scan` |

### Types, Errors, Constants
None. Pure interface.

## NatSpec Coverage

| Function | Description | @param | @return |
|----------|------------|--------|---------|
| `bytecode` | Yes | Yes | Yes |
| `bytecodeHash` | Yes | Yes | Yes (inaccurate) |
| `scanEVMOpcodesPresentInAccount` | Yes (24 lines) | **NO** | **NO** |

## Findings

### A04-P3-1 [MEDIUM] Missing `@param` and `@return` tags for `scanEVMOpcodesPresentInAccount`

Lines 30-55: Extensive free-form docs but no formal `@param` or `@return` NatSpec tags. The V2 interface includes both tags for the identical signature.

### A04-P3-2 [LOW] Typo "prescence" on line 43

Should be "presence". Same typo exists in V2.

### A04-P3-3 [MEDIUM] `bytecodeHash` return docs oversimplify EIP-1052 behavior

Lines 26-27: States "Will be `0` (NOT the hash of empty bytes) for non-contract accounts." This conflates non-existent accounts (returns `0`) with funded EOAs (returns `keccak256("")`). Same issue as V2.

### A04-P3-4 [LOW] Functions use implicit `@notice` instead of explicit tags

All three functions use plain `///` comments without `@notice` or `@dev` prefix.

### A04-P3-5 [INFO] No deprecation notice in NatSpec

The interface resides in `deprecated/` but NatSpec does not mention deprecation or point to V2.

### A04-P3-6 [INFO] No mention of EOF bytecode revert behavior

Documentation does not note that the underlying library reverts on EOF-formatted bytecode.
