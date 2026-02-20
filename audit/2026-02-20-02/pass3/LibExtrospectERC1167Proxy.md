# A03 -- Documentation Audit: LibExtrospectERC1167Proxy.sol

**Auditor:** A03
**Date:** 2026-02-20
**Source:** `src/lib/LibExtrospectERC1167Proxy.sol`

---

## Findings

### A03-1 | LOW | Offset constant docs do not explain memory layout assumptions

Lines 19-20 (`ERC1167_PREFIX_START`), 22-23 (`ERC1167_SUFFIX_START`), 32 (`ERC1167_IMPLEMENTATION_ADDRESS_OFFSET`): The `0x20` offset accounts for the 32-byte length word preceding `bytes memory` data, but the NatSpec does not mention this convention.

### A03-2 | LOW | Prefix and suffix constant documentation is near-identical

Lines 5-6 and 8-9: Both share the same leading sentence. Could differentiate by describing functional roles (prefix = delegatecall setup; suffix = return/revert forwarding).
