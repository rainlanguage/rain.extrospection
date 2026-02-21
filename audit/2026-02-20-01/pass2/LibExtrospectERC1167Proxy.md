# Pass 2: Test Coverage — A08 — LibExtrospectERC1167Proxy

## Evidence of Thorough Reading

### Source file — constants (lines 7–33)

| Name | Line | Value / Expression |
|---|---|---|
| `ERC1167_PREFIX` | 7 | `hex"363d3d373d3d3d363d73"` |
| `ERC1167_SUFFIX` | 10 | `hex"5af43d82803e903d91602b57fd5bf3"` |
| `ERC1167_PREFIX_HASH` | 14 | `keccak256(ERC1167_PREFIX)` |
| `ERC1167_SUFFIX_HASH` | 18 | `keccak256(ERC1167_SUFFIX)` |
| `ERC1167_PREFIX_START` | 21 | `0x20` |
| `ERC1167_SUFFIX_START` | 24 | `0x20 + ERC1167_PROXY_LENGTH - ERC1167_SUFFIX_LENGTH` |
| `ERC1167_PREFIX_LENGTH` | 26 | `10` |
| `ERC1167_SUFFIX_LENGTH` | 28 | `15` |
| `ERC1167_PROXY_LENGTH` | 31 | `45` |
| `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET` | 33 | `30` |

### Source file — function (lines 45–94)

`isERC1167Proxy(bytes memory bytecode) internal pure returns (bool result, address implementationAddress)`

### Test file — all 14 test functions

| Function | Purpose |
|---|---|
| `testIsERC1167ProxyLength` | Fuzz: length != 45 always fails |
| `testIsERC1167ProxyPrefixFail` | Fuzz: bad prefix, unconstrained length |
| `testIsERC1167ProxyPrefixFail45Bytes` | Fuzz: bad prefix, 45-byte bytecode |
| `testIsERC1167ProxySuffixFail` | Fuzz: bad suffix, unconstrained length |
| `testIsERC1167ProxySuffixFail45Bytes` | Fuzz: bad suffix, 45-byte bytecode |
| `testIsERC1167ProxyBothPrefixAndSuffixFail` | Fuzz: both bad, 45-byte bytecode |
| `testIsERC1167ProxySuccess` | Fuzz: correct proxy, checks address returned |
| `testIsERC1167ProxySlowFail` | Differential oracle vs slow impl, fail cases |
| `testIsERC1167ProxySlowSuccess` | Differential oracle vs slow impl, success cases |
| `testIsERC1167ProxyGasFailLength` | Gas snapshot: length failure |
| `testIsERC1167ProxyGasFailPrefix` | Gas snapshot: prefix failure |
| `testIsERC1167ProxyGasFailSuffix` | Gas snapshot: suffix failure |
| `testERC1167Constants` | Unit: constants match ERC-1167 spec |
| `testIsERC1167ProxyGasSuccess` | Gas snapshot: success path |

## Findings

No test coverage findings.
