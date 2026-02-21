# A07 Pass 4 (Code Quality): `src/lib/LibExtrospectERC1167Proxy.sol`

## Evidence of Thorough Reading

- Library: `LibExtrospectERC1167Proxy` (line 36)
- 10 file-level constants (lines 5-33)
- Function: `isERC1167Proxy` (line 43)
- No errors, types, or events

## Findings

### A07-P4-1 [INFO] Length constants hardcoded rather than derived from byte constant lengths

`ERC1167_PREFIX_LENGTH` = 10, `ERC1167_SUFFIX_LENGTH` = 15 are hardcoded. ERC-1167 is finalized so values will never change. Compile-time constant expression constraints make derivation impractical.

### A07-P4-2 [INFO] `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET` naming could clarify memory offset semantics

Value 30 is the offset from the `bytes memory` pointer for `mload`, not a data-relative offset. Requires understanding of the `uint160` masking to verify correctness.

### A07-P4-3 [INFO] Unnecessary scope block around length check (lines 45-57)

No local variables defined in this scope.

### A07-P4-4 [INFO] Inconsistent scoping between prefix and suffix check sections

Prefix check (lines 59-65) declares variables in outer `unchecked` scope; suffix check (lines 67-75) wraps in `{ ... }` scope block.

### A07-P4-5 [INFO] Branchless result accumulation -- intentional gas optimization

After prefix check fails, suffix `keccak256` still executes. Avoids conditional jump penalty on success path. Wasted gas on failure is negligible vs `extcodecopy` cost.

### A07-P4-6 [INFO] Pragma `^0.8.18` vs foundry.toml `0.8.25` -- standard practice
