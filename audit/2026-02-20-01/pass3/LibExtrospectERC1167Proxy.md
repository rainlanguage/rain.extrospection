# Pass 3: Documentation — A08 — LibExtrospectERC1167Proxy

## Evidence of Thorough Reading

**Library:** `LibExtrospectERC1167Proxy` (line 38)

**Function:** `isERC1167Proxy(bytes memory bytecode)` (line 45)

**Constants (10):** ERC1167_PREFIX (7), ERC1167_SUFFIX (10), ERC1167_PREFIX_HASH (14), ERC1167_SUFFIX_HASH (18), ERC1167_PREFIX_START (21), ERC1167_SUFFIX_START (24), ERC1167_PREFIX_LENGTH (26), ERC1167_SUFFIX_LENGTH (28), ERC1167_PROXY_LENGTH (31), ERC1167_IMPLEMENTATION_ADDRESS_OFFSET (33)

All constants have `@dev` comments. Library has `@title` and `@notice`. Function has `@notice`, `@param`, both `@return` tags. ERC-1167 prefix/suffix verified against the EIP specification.

## Findings

### A08-1: `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET` comment does not document the mload+mask trick — **INFO**

The value 30 is a raw pointer offset, not a data-relative offset. The `@dev` comment says only "The implementation address read offset is constant" without explaining the non-obvious mload+uint160 mask that makes the value correct.

### A08-2: `_START` constant comments don't clarify they are memory offsets from the `bytes` pointer — **INFO**

`ERC1167_PREFIX_START = 0x20` and `ERC1167_SUFFIX_START = 62` don't state they account for the 32-byte ABI length slot.

### A08-3: `isERC1167Proxy` NatSpec omits length early-return and branchless suffix check — **INFO**

The function returns `(false, address(0))` immediately for length != 45, and computes suffix hash unconditionally even after prefix mismatch. Neither is documented for callers reasoning about gas costs.
