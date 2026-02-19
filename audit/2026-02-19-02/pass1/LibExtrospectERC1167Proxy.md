# Audit: LibExtrospectERC1167Proxy.sol

**Auditor Agent:** A07
**Date:** 2026-02-19
**File:** `src/lib/LibExtrospectERC1167Proxy.sol`

## Evidence of Thorough Reading

### Library/Contract Name

- `LibExtrospectERC1167Proxy` (line 36) -- declared as `library`

### Functions

| Function Name | Line | Visibility | Mutability |
|---|---|---|---|
| `isERC1167Proxy` | 43 | `internal` | `pure` |

This is the only function in the library. Its full signature is:
```solidity
function isERC1167Proxy(bytes memory bytecode) internal pure returns (bool result, address implementationAddress)
```

### Types, Errors, and Constants Defined

No custom types (structs, enums), errors, or events are defined.

**File-level constants (all declared outside the library):**

| Constant | Line | Type | Value |
|---|---|---|---|
| `ERC1167_PREFIX` | 7 | `bytes` | `hex"363d3d373d3d3d363d73"` (10 bytes) |
| `ERC1167_SUFFIX` | 10 | `bytes` | `hex"5af43d82803e903d91602b57fd5bf3"` (15 bytes) |
| `ERC1167_PREFIX_HASH` | 14 | `bytes32` | `keccak256(ERC1167_PREFIX)` |
| `ERC1167_SUFFIX_HASH` | 18 | `bytes32` | `keccak256(ERC1167_SUFFIX)` |
| `ERC1167_PREFIX_START` | 21 | `uint256` | `0x20` (32) |
| `ERC1167_SUFFIX_START` | 24 | `uint256` | `0x20 + ERC1167_PROXY_LENGTH - ERC1167_SUFFIX_LENGTH` = 62 (0x3e) |
| `ERC1167_PREFIX_LENGTH` | 26 | `uint256` | `10` |
| `ERC1167_SUFFIX_LENGTH` | 28 | `uint256` | `15` |
| `ERC1167_PROXY_LENGTH` | 31 | `uint256` | `20 + ERC1167_PREFIX_LENGTH + ERC1167_SUFFIX_LENGTH` = 45 |
| `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET` | 33 | `uint256` | `ERC1167_PREFIX_LENGTH + 20` = 30 |

### File Structure Summary

- Lines 1-3: SPDX license, copyright, and pragma `^0.8.18`
- Lines 5-33: Ten file-level constants defining ERC1167 proxy bytecode layout
- Lines 35-93: Library `LibExtrospectERC1167Proxy` with a single function `isERC1167Proxy`
- Total: 94 lines

## Detailed Analysis

### ERC1167 Specification Correctness

The ERC-1167 Minimal Proxy Contract specification (https://eips.ethereum.org/EIPS/eip-1167) defines the runtime bytecode as:

```
363d3d373d3d3d363d73 <20-byte-address> 5af43d82803e903d91602b57fd5bf3
```

- **Prefix** `363d3d373d3d3d363d73` = 10 bytes. The constant `ERC1167_PREFIX` on line 7 matches exactly.
- **Suffix** `5af43d82803e903d91602b57fd5bf3` = 15 bytes. The constant `ERC1167_SUFFIX` on line 10 matches exactly.
- **Total length** = 10 + 20 + 15 = 45 bytes. `ERC1167_PROXY_LENGTH` on line 31 evaluates to 45. Correct.

### Constant Arithmetic Verification

- `ERC1167_PREFIX_START = 0x20 = 32`. For a `bytes memory` variable, the pointer points to the length word (32 bytes). Data starts at offset 0x20. This correctly targets the first byte of data. **Correct.**
- `ERC1167_SUFFIX_START = 0x20 + 45 - 15 = 62 = 0x3e`. The suffix begins at data byte 30 (0-indexed), which is offset 32 + 30 = 62 from the `bytecode` pointer. Since prefix is 10 bytes and address is 20 bytes, byte 30 is exactly where the suffix begins. **Correct.**
- `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET = 10 + 20 = 30`. Used in `mload(add(bytecode, 30))`. This loads 32 bytes starting at `bytecode + 30`, which captures the last 2 bytes of the length word, all 10 bytes of the prefix, and all 20 bytes of the address. After masking with `type(uint160).max`, only the lowest 20 bytes remain, which is exactly the address. **Correct.**

### Assembly Memory Safety Analysis

**Block 1 (lines 63-65) -- Prefix check:**
```solidity
assembly ("memory-safe") {
    result := and(result, eq(keccak256(add(bytecode, prefixStart), prefixLength), prefixHash))
}
```
- Reads from `bytecode + 0x20` for 10 bytes. This is within the `bytecode` memory allocation (length word + 45 data bytes = 77 bytes from `bytecode`). The read range is `[bytecode+32, bytecode+42)`, which is well within bounds. **Memory-safe: correct.**

**Block 2 (lines 72-74) -- Suffix check:**
```solidity
assembly ("memory-safe") {
    result := and(result, eq(keccak256(add(bytecode, suffixStart), suffixLength), suffixHash))
}
```
- Reads from `bytecode + 62` for 15 bytes. Range is `[bytecode+62, bytecode+77)`. The total allocation of `bytecode` is 77 bytes from the pointer (32 length + 45 data). So this reads up to the last byte. **Memory-safe: correct.**

**Block 3 (lines 83-88) -- Address extraction:**
```solidity
assembly ("memory-safe") {
    implementationAddress := and(
        mload(add(bytecode, implementationAddressOffset)),
        implementationAddressMask
    )
}
```
- Reads 32 bytes starting at `bytecode + 30`. Range is `[bytecode+30, bytecode+62)`. This is within the allocation bounds. **Memory-safe: correct.**
- The `and` mask with `type(uint160).max` correctly isolates the lowest 20 bytes (the address). **Correct.**

### Boundary Condition Analysis

1. **Non-proxy bytecode (wrong length):** Line 50 checks `bytecode.length != ERC1167_PROXY_LENGTH` and returns `(false, address(0))` immediately. Any bytecode that is not exactly 45 bytes is rejected. **Correct.**

2. **Short bytecode / empty bytecode:** Falls into the length check above since 0 != 45. Returns `(false, address(0))`. **Correct.**

3. **45-byte bytecode with wrong prefix:** The prefix hash comparison at line 64 fails, `result` becomes `false`. The suffix check still executes (no short-circuit), but `result` stays `false`. Due to `if (result)` at line 78, the address extraction is skipped and `implementationAddress` remains `address(0)`. **Correct.**

4. **45-byte bytecode with correct prefix but wrong suffix:** The prefix check passes, but suffix check fails, `result` becomes `false`. Address extraction is skipped. **Correct.**

5. **Valid proxy with `address(0)` as implementation:** Returns `(true, address(0))`. This is documented in `IExtrospectERC1167ProxyV1` (lines 12-15) as a known edge case that callers must handle. **Correct by design.**

### `unchecked` Block Analysis

The entire function body is wrapped in `unchecked` (line 44). There is no arithmetic within the function body itself -- all arithmetic is in the compile-time constants. The only operations inside the function are comparisons, memory reads, and boolean logic. Therefore `unchecked` has no effect on runtime behavior. **Safe.**

## Findings

### A07-1: No short-circuit on prefix failure before suffix hashing (INFO)

**Severity:** INFO

**Location:** Lines 59-75

**Description:**

When the prefix check fails (line 64), `result` is set to `false` via the `and` operation, but execution continues to the suffix hash check (line 73). The suffix `keccak256` is computed even though the result is already known to be `false`. This is a minor gas inefficiency for the non-proxy case.

The current design is intentional: using branchless `and` operations avoids conditional jumps and keeps the code predictable. For the success path (valid proxy detection), this is optimal. For non-proxy bytecode that passes the length check but fails the prefix check, a small amount of gas is wasted computing the suffix hash.

Given that the length check (line 50) is the primary fast-path rejection for non-proxies (most accounts will not have exactly 45 bytes of code), and that cases reaching the prefix check with wrong prefix bytes are rare, this tradeoff is reasonable.

**Recommendation:** No change needed. This is a deliberate design choice favoring simplicity and avoiding branch misprediction. The gas impact is negligible in practice.

### A07-2: `memory-safe` annotation correctness is tightly coupled to constant values (INFO)

**Severity:** INFO

**Location:** Lines 63, 72, 83

**Description:**

All three assembly blocks are annotated with `"memory-safe"`. The correctness of this annotation depends on the assumption that the constants `ERC1167_PREFIX_START`, `ERC1167_SUFFIX_START`, `ERC1167_SUFFIX_LENGTH`, and `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET` are correctly defined such that all memory reads fall within the allocated `bytecode` region.

This is currently correct (verified above). However, the safety guarantee is implicit -- if any constant were changed (e.g., if `ERC1167_SUFFIX_START` were increased beyond the allocation boundary), the assembly blocks would read beyond the allocated memory while still claiming to be memory-safe, which could cause undefined behavior in the optimizer.

The compile-time constant expressions provide strong protection against accidental drift since changing any single constant would cause others that depend on it to adjust. The coupling between constants is well-designed (e.g., `ERC1167_SUFFIX_START` is derived from `ERC1167_PROXY_LENGTH` and `ERC1167_SUFFIX_LENGTH`).

**Recommendation:** No change needed. The constant design inherently protects against inconsistency. This is informational context for future maintainers.

### A07-3: The `unchecked` block wrapping the entire function is unnecessary but harmless (INFO)

**Severity:** INFO

**Location:** Line 44

**Description:**

The `unchecked` block wraps the entire function body, but the function contains no arithmetic operations at runtime -- all arithmetic occurs in compile-time constant expressions (which are not subject to overflow checks regardless). The runtime operations are: a length comparison, three assembly blocks (which are inherently unchecked), a boolean `if`, and return statements.

The `unchecked` block therefore has no effect on the generated bytecode. It does not introduce any risk, but it also provides no benefit.

**Recommendation:** Informational only. Removing `unchecked` would not change the compiled output. Keeping it is not harmful and may serve as documentation of intent that the developer considered overflow.

## Summary

No security vulnerabilities were identified in `LibExtrospectERC1167Proxy.sol`. The library is a well-constructed, minimal implementation of ERC-1167 proxy detection.

**Correctness of ERC1167 detection:** The prefix and suffix bytes exactly match the EIP-1167 specification. The length check, prefix hash comparison, suffix hash comparison, and address extraction are all arithmetically correct.

**Memory safety:** All three assembly blocks correctly read within the bounds of the `bytecode` memory allocation. The `"memory-safe"` annotations are accurate.

**Address extraction:** The implementation address is correctly extracted by loading 32 bytes at a carefully chosen offset and masking with `type(uint160).max` to isolate the 20-byte address.

**Boundary conditions:** Non-proxy bytecode (wrong length, wrong prefix, wrong suffix) is correctly rejected with `(false, address(0))`. The `address(0)` implementation edge case is documented in the corresponding interface.

**Test coverage:** The test file `test/src/lib/LibExtrospectERC1167Proxy.isERC1167Proxy.t.sol` includes fuzz tests for wrong length, wrong prefix, wrong suffix, correct proxy detection, and equivalence with a reference slow implementation. Gas benchmark tests cover all four code paths (fail on length, fail on prefix, fail on suffix, success).

All three findings are classified as INFO-level observations. There are no CRITICAL, HIGH, MEDIUM, or LOW findings.
