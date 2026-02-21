# A03 -- Test Coverage Audit: LibExtrospectERC1167Proxy

**Auditor:** A03
**Date:** 2026-02-20
**Source:** `src/lib/LibExtrospectERC1167Proxy.sol`

---

## Source File Inventory

**Library:** `LibExtrospectERC1167Proxy`

### Constants (file scope)

| Name | Line |
|---|---|
| `ERC1167_PREFIX` | 7 |
| `ERC1167_SUFFIX` | 10 |
| `ERC1167_PREFIX_HASH` | 14 |
| `ERC1167_SUFFIX_HASH` | 18 |
| `ERC1167_PREFIX_START` | 21 |
| `ERC1167_SUFFIX_START` | 24 |
| `ERC1167_PREFIX_LENGTH` | 26 |
| `ERC1167_SUFFIX_LENGTH` | 28 |
| `ERC1167_PROXY_LENGTH` | 31 |
| `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET` | 33 |

### Functions

| Function | Line |
|---|---|
| `isERC1167Proxy` | 45 |

---

## Findings

### A03-1 | LOW | No explicit test for exactly 44-byte and 46-byte inputs (off-by-one boundary)

The fuzz test `testIsERC1167ProxyLength` covers `bytecode.length != 45` but there is no concrete test for the boundaries at 44 and 46 bytes. The fuzzer likely hits these but an explicit test would document the boundary.
