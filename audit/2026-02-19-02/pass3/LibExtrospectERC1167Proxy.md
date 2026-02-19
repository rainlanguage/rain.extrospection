# A07 Pass 3 (Documentation): `src/lib/LibExtrospectERC1167Proxy.sol`

## Evidence of Thorough Reading

### Library Name
- `LibExtrospectERC1167Proxy` (line 36)

### Constants (lines 5-33)
| Constant | Line | Type |
|----------|------|------|
| `ERC1167_PREFIX` | 7 | `bytes` |
| `ERC1167_SUFFIX` | 10 | `bytes` |
| `ERC1167_PREFIX_HASH` | 14 | `bytes32` |
| `ERC1167_SUFFIX_HASH` | 18 | `bytes32` |
| `ERC1167_PREFIX_START` | 21 | `uint256` |
| `ERC1167_SUFFIX_START` | 24 | `uint256` |
| `ERC1167_PREFIX_LENGTH` | 26 | `uint256` |
| `ERC1167_SUFFIX_LENGTH` | 28 | `uint256` |
| `ERC1167_PROXY_LENGTH` | 31 | `uint256` |
| `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET` | 33 | `uint256` |

### Functions
| Function | Line | Visibility | Mutability |
|----------|------|------------|------------|
| `isERC1167Proxy` | 43 | internal | pure |

### Types, Errors
None.

## NatSpec Coverage

- `isERC1167Proxy`: `@notice`, `@param bytecode`, `@return result`, `@return implementationAddress`. All present and accurate.
- All 10 constants have `@dev` documentation.
- No undocumented functions.

## Findings

### A07-P3-1 [LOW] Library lacks `@notice`/`@dev` description

Line 35: Only `@title LibExtrospectERC1167Proxy` with no description of purpose. The interface has a thorough `@notice` but the library does not.

### A07-P3-2 [INFO] Function NatSpec does not warn about `address(0)` edge case

The interface uses emphatic "MUST" language about checking `result` before trusting `implementationAddress`. The library's NatSpec is accurate but uses weaker language. Since the function is `internal`, this is informational.

### A07-P3-3 [INFO] No link to EIP-1167 in the library

The interface links to EIP-1167 but the library containing the actual bytecode constants does not.

### A07-P3-4 [INFO] `ERC1167_PREFIX_START` and `ERC1167_SUFFIX_START` do not explain the 0x20 memory offset

The `0x20` base offset (Solidity's 32-byte length prefix for `bytes memory`) is not explained in the NatSpec.

### A07-P3-5 [INFO] Address extraction assembly comment does not explain masking

The comment says "extract the implementation address" but does not explain the `mload` + `type(uint160).max` masking operation.
