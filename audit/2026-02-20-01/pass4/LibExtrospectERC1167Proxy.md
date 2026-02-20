# Pass 4: Code Quality — A08 — LibExtrospectERC1167Proxy

## Evidence of Thorough Reading

**File:** `src/lib/LibExtrospectERC1167Proxy.sol` (95 lines)

**Library:** `LibExtrospectERC1167Proxy` (line 38)

**Constants (10):** ERC1167_PREFIX (7), ERC1167_SUFFIX (10), ERC1167_PREFIX_HASH (14), ERC1167_SUFFIX_HASH (18), ERC1167_PREFIX_START (21), ERC1167_SUFFIX_START (24), ERC1167_PREFIX_LENGTH (26), ERC1167_SUFFIX_LENGTH (28), ERC1167_PROXY_LENGTH (31), ERC1167_IMPLEMENTATION_ADDRESS_OFFSET (33)

**Functions (1):** `isERC1167Proxy(bytes memory bytecode)` (line 45)

**Assembly blocks (3):** all annotated `"memory-safe"`.

## Findings

### A08-1: Prefix check locals are not scope-enclosed, unlike suffix check locals — **INFO**

The suffix assembly block (lines 69–77) is wrapped in a bare `{}` block. The prefix assembly block (lines 61–67) is NOT wrapped. The inconsistency suggests the scoping convention was applied incompletely.

### A08-2: `else` branch after unconditional `return` is redundant — **INFO**

Line 54 uses an `else` clause that is unreachable from the preceding `return`. `LibExtrospectBytecode` consistently uses guard-clause style with no `else`.

### A08-3: `unchecked` wrapping the entire function body diverges from `LibExtrospectBytecode` — **INFO**

`isERC1167Proxy` wraps its complete body in `unchecked` (line 46). All arithmetic is either inside `assembly` blocks or is a comparison. The `unchecked` has no effect on code generation. `LibExtrospectBytecode` does not use `unchecked` anywhere.

### A08-4: Magic decimal literal `20` used for address byte-width instead of a named constant — **INFO**

The literal `20` appears twice in constant definitions (lines 31, 33) representing the byte-width of an Ethereum address. A named constant would make the arithmetic self-documenting.

### A08-5: Bare `{}` scope blocks are not used in `LibExtrospectBytecode` — **INFO**

Three bare `{}` blocks appear in `isERC1167Proxy` to limit local variable scope. `LibExtrospectBytecode` declares assembly-adjacent locals directly in the function scope without bare blocks.
