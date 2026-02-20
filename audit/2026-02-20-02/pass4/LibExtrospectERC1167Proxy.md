# A03 -- Code Quality Audit: LibExtrospectERC1167Proxy.sol

**Auditor:** A03
**Date:** 2026-02-20
**Source:** `src/lib/LibExtrospectERC1167Proxy.sol`

---

## Findings

### A03-1 | LOW | Constant definition ordering creates forward references

Line 24: `ERC1167_SUFFIX_START` references `ERC1167_PROXY_LENGTH` (line 31) and `ERC1167_SUFFIX_LENGTH` (line 28), both defined after it. Solidity resolves file-level constants at compile time regardless of order, but this hinders top-to-bottom readability.

### A03-2 | LOW | Missing EIP-1167 specification URL in source file NatSpec

The hex byte sequences for `ERC1167_PREFIX` and `ERC1167_SUFFIX` have no reference to the EIP-1167 specification. The test file references the URL, but the source does not. Other source files (EVMOpcodes.sol, LibExtrospectBytecode.sol) include specification URLs.
