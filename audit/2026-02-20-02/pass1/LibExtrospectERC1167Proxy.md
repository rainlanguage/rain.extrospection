# A03 Security Audit: `src/lib/LibExtrospectERC1167Proxy.sol`

**Auditor Agent:** A03
**Date:** 2026-02-20
**File:** `src/lib/LibExtrospectERC1167Proxy.sol` (95 lines)

---

## Evidence of Thorough Reading

### Library Name

- `LibExtrospectERC1167Proxy` -- declared as `library` at line 38.

### Functions

| Function | Line | Visibility | Mutability | Signature |
|---|---|---|---|---|
| `isERC1167Proxy` | 45 | `internal` | `pure` | `(bytes memory bytecode) returns (bool result, address implementationAddress)` |

This is the only function in the library.

### Constants (file-level, lines 5--33)

| Constant | Line | Type | Value |
|---|---|---|---|
| `ERC1167_PREFIX` | 7 | `bytes` | `hex"363d3d373d3d3d363d73"` (10 bytes) |
| `ERC1167_SUFFIX` | 10 | `bytes` | `hex"5af43d82803e903d91602b57fd5bf3"` (15 bytes) |
| `ERC1167_PREFIX_HASH` | 14 | `bytes32` | `keccak256(ERC1167_PREFIX)` |
| `ERC1167_SUFFIX_HASH` | 18 | `bytes32` | `keccak256(ERC1167_SUFFIX)` |
| `ERC1167_PREFIX_START` | 21 | `uint256` | `0x20` (32) |
| `ERC1167_SUFFIX_START` | 24 | `uint256` | `0x20 + ERC1167_PROXY_LENGTH - ERC1167_SUFFIX_LENGTH` = 62 |
| `ERC1167_PREFIX_LENGTH` | 26 | `uint256` | `10` |
| `ERC1167_SUFFIX_LENGTH` | 28 | `uint256` | `15` |
| `ERC1167_PROXY_LENGTH` | 31 | `uint256` | `20 + ERC1167_PREFIX_LENGTH + ERC1167_SUFFIX_LENGTH` = 45 |
| `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET` | 33 | `uint256` | `ERC1167_PREFIX_LENGTH + 20` = 30 |

### Types, Errors, Events

None. The file defines no custom types (structs, enums), no errors, and no events.

---

## Detailed Security Analysis

### 1. ERC-1167 Specification Correctness

The EIP-1167 standard defines the minimal proxy runtime bytecode as:

```
363d3d373d3d3d363d73 <20-byte-address> 5af43d82803e903d91602b57fd5bf3
```

- `ERC1167_PREFIX` (line 7): `hex"363d3d373d3d3d363d73"` -- matches the specification exactly.
- `ERC1167_SUFFIX` (line 10): `hex"5af43d82803e903d91602b57fd5bf3"` -- matches the specification exactly.
- Total length: 10 + 20 + 15 = 45 bytes. `ERC1167_PROXY_LENGTH` evaluates to 45. Correct.

### 2. Constant Arithmetic Verification

All constants are compile-time evaluated. Manual verification:

- `ERC1167_PREFIX_START = 0x20 = 32`. For `bytes memory`, the pointer references the 32-byte length word. Data begins at offset `0x20` from the pointer. This correctly targets the first data byte. **Correct.**
- `ERC1167_SUFFIX_START = 0x20 + 45 - 15 = 62`. The suffix starts at data byte index 30 (after 10-byte prefix + 20-byte address). Memory offset from the pointer: 32 + 30 = 62. **Correct.**
- `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET = 10 + 20 = 30`. Used in `mload(add(bytecode, 30))`. This loads 32 bytes beginning at `bytecode + 30`. The loaded word contains: 2 bytes of the length slot, 10 bytes of prefix, and 20 bytes of the address. Masking with `type(uint160).max` isolates the lowest 20 bytes, which is the implementation address. **Correct.**

### 3. Assembly Memory Safety

**Block 1 (lines 65--67) -- Prefix hash check:**
```solidity
assembly ("memory-safe") {
    result := and(result, eq(keccak256(add(bytecode, prefixStart), prefixLength), prefixHash))
}
```
- Reads `[bytecode + 32, bytecode + 42)` -- 10 bytes within the 77-byte allocation (32-byte length word + 45-byte data). **Safe. No out-of-bounds read.**

**Block 2 (lines 74--76) -- Suffix hash check:**
```solidity
assembly ("memory-safe") {
    result := and(result, eq(keccak256(add(bytecode, suffixStart), suffixLength), suffixHash))
}
```
- Reads `[bytecode + 62, bytecode + 77)` -- 15 bytes ending exactly at the allocation boundary. **Safe. No out-of-bounds read.**

**Block 3 (lines 85--90) -- Address extraction:**
```solidity
assembly ("memory-safe") {
    implementationAddress := and(
        mload(add(bytecode, implementationAddressOffset)),
        implementationAddressMask
    )
}
```
- `mload` reads 32 bytes at `[bytecode + 30, bytecode + 62)`. This is entirely within the 77-byte allocation. **Safe. No out-of-bounds read.**
- The mask `type(uint160).max` correctly isolates the lowest 20 bytes. **Correct.**

All three blocks are read-only (no `mstore` or `sstore`). No memory is allocated, freed, or overwritten. The `"memory-safe"` annotations are accurate.

### 4. Edge Case Analysis

| Edge Case | Behavior | Correct? |
|---|---|---|
| Empty bytecode (`bytes("")`) | Length 0 != 45, returns `(false, address(0))` at line 53 | Yes |
| Short bytecode (< 45 bytes) | Length check fails, early return | Yes |
| Long bytecode (> 45 bytes) | Length check fails, early return | Yes |
| 45-byte non-proxy (random bytes) | Prefix hash mismatch, `result = false`; address extraction skipped | Yes |
| Valid prefix, invalid suffix (45 bytes) | Suffix hash mismatch, `result = false`; address extraction skipped | Yes |
| Invalid prefix, valid suffix (45 bytes) | Prefix hash mismatch, `result = false`; suffix check still runs but `result` stays `false`; address extraction skipped | Yes |
| Valid proxy with `address(0)` implementation | Returns `(true, address(0))` -- documented edge case | Yes (by design) |
| Valid proxy with any address | Returns `(true, <address>)` | Yes |

### 5. Spoofability / Crafted Bytecode Analysis

An attacker might try to craft bytecode that is detected as an ERC-1167 proxy when it is not. Analysis:

- The function requires the bytecode to be **exactly** 45 bytes, matching ERC1167_PREFIX exactly at the start and ERC1167_SUFFIX exactly at the end. The only degrees of freedom are the 20 address bytes in the middle.
- There is no keccak256 collision concern: the prefix and suffix are compared as exact byte sequences (via hash-then-compare against a known hash). A 10-byte prefix has only 2^80 possibilities; the hash comparison is deterministic, not probabilistic. The function computes `keccak256` of the candidate region and compares it to the precomputed hash of the known prefix/suffix. A match requires the bytes to be identical (absent a keccak256 collision, which is computationally infeasible).
- The function cannot be fooled into identifying non-1167 bytecode as a proxy. Conversely, it correctly identifies all conforming ERC-1167 proxies.
- **Note:** ERC-1167 variants exist in the wild (e.g., OpenZeppelin's UUPS proxies, Vyper minimal proxies, or custom clones with different prefix/suffix). This library intentionally only detects the canonical EIP-1167 form. This is correct behavior, not a bug.

### 6. `unchecked` Block Analysis

The entire function body is wrapped in `unchecked` (line 46). No runtime arithmetic occurs inside the function -- all arithmetic is in compile-time constant expressions (which are not subject to overflow checks). The runtime operations are: one comparison (`bytecode.length != ERC1167_PROXY_LENGTH`), three inline assembly blocks, one boolean `if`, and return statements. The `unchecked` block is inert.

---

## Findings

### A03-1 [INFO] No short-circuit on prefix failure before suffix hash computation

**Location:** Lines 61--77

**Description:** When the prefix check fails at line 66, `result` becomes `false` via the branchless `and` operation, but execution falls through to the suffix hash check at lines 74--76. The suffix `keccak256` is computed unnecessarily.

**Impact:** Minor gas inefficiency on the non-proxy path for the rare case of a contract with exactly 45 bytes of bytecode but an incorrect prefix. The overwhelming majority of rejections happen at the length check (line 52), making this a negligible concern in practice.

**Assessment:** This is an intentional design choice. Branchless logic avoids a conditional jump, optimizing the success (proxy-detected) path. The gas cost of a single `keccak256` on 15 bytes is trivial compared to the `EXTCODECOPY` that the caller must have already performed.

### A03-2 [INFO] `unchecked` block wrapping the entire function is inert

**Location:** Line 46

**Description:** The `unchecked` block wraps the entire function body, but no runtime arithmetic occurs within it. All addition/subtraction is in compile-time constants. The block has no effect on compiled output.

**Assessment:** Harmless. May serve as developer intent documentation. Removing it would not change behavior.

### A03-3 [INFO] `memory-safe` annotation correctness depends on constant invariants

**Location:** Lines 65, 74, 85

**Description:** The three assembly blocks are annotated `"memory-safe"`. This is correct only because the constants (`ERC1167_PREFIX_START`, `ERC1167_SUFFIX_START`, `ERC1167_SUFFIX_LENGTH`, `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET`) are defined such that all reads fall within the `bytecode` memory allocation. The constants are derived from each other (e.g., `ERC1167_SUFFIX_START` depends on `ERC1167_PROXY_LENGTH` and `ERC1167_SUFFIX_LENGTH`), which inherently protects against inconsistency.

**Assessment:** The coupling between constants is well-designed. A future change to any single constant would propagate correctly through the dependency chain. The `"memory-safe"` annotations are valid.

### A03-4 [INFO] Detection limited to canonical ERC-1167 form only

**Location:** Lines 7, 10 (prefix/suffix constants)

**Description:** The library detects only the exact bytecode format specified in EIP-1167. Variants in the wild include:
- Vyper minimal proxies (different bytecode structure)
- EIP-1167 with PUSH0 optimization (proposed in ERC-7511, using `365f5f375f5f365f73...` prefix)
- Custom clone factories that embed extra logic

These are not detected by `isERC1167Proxy`. This is by design -- the library's purpose is to detect the canonical EIP-1167 form, and its name explicitly states "ERC1167". Non-detection of variant forms is correct behavior.

**Assessment:** Informational. Callers should be aware that a `false` result does not guarantee the contract is not a proxy of some kind, only that it is not a canonical ERC-1167 proxy.

### A03-5 [INFO] Hash-based comparison is equivalent to direct byte comparison for these sizes

**Location:** Lines 65--66, 74--75

**Description:** The prefix (10 bytes) and suffix (15 bytes) are compared by hashing the candidate region with `keccak256` and comparing against precomputed hashes. For inputs this small, the probability of a keccak256 collision is negligible (2^-256). Direct byte comparison (e.g., via `eq(mload(...), ...)` with masking) would also work for the 10-byte prefix and could potentially be slightly cheaper than `keccak256`. However, for the 15-byte suffix (which does not fit neatly in a single 32-byte word without careful masking), the hash approach is cleaner and avoids boundary complexity.

**Assessment:** The hash-based approach is sound. The gas difference for `keccak256` on 10--15 bytes versus masked word comparison is minimal and the hash approach is safer against subtle masking errors.

### A03-6 [INFO] `address(0)` implementation is a valid detection result

**Location:** Lines 80--91

**Description:** If the bytecode is a valid ERC-1167 proxy pointing to `address(0)`, the function returns `(true, address(0))`. A caller that uses only the `implementationAddress` return value without checking `result` could mistake a failed detection (which also returns `address(0)`) for a valid proxy pointing to the zero address. The natspec on line 44 documents this: "This is only valid if `result` is true, else it is zero."

**Assessment:** Correctly documented. Callers must check the `result` boolean before using `implementationAddress`. This is standard practice for dual-return-value patterns in Solidity.

---

## Summary

No CRITICAL, HIGH, MEDIUM, or LOW security issues were identified.

The library is a well-constructed, minimal, and correct implementation of ERC-1167 proxy detection. Key security properties verified:

1. **ERC-1167 specification conformance:** Prefix and suffix bytes exactly match the EIP-1167 standard. Total length of 45 bytes is correct.
2. **Memory safety:** All three assembly blocks read within the bounds of the `bytecode` memory allocation. The `"memory-safe"` annotations are accurate. No writes to memory occur.
3. **Address extraction correctness:** The `mload` + `uint160` mask correctly extracts the 20-byte implementation address from its known position.
4. **Rejection correctness:** Non-proxy bytecode is correctly rejected via length check (primary fast path) and prefix/suffix hash comparison (secondary path). All edge cases produce `(false, address(0))`.
5. **Spoofability:** The detection cannot be fooled. Matching requires the exact 10-byte prefix and 15-byte suffix at the correct positions in a 45-byte sequence, with no degrees of freedom except the 20-byte address.
6. **Test coverage:** The test suite includes fuzz tests for wrong length, wrong prefix (both arbitrary length and fixed 10-byte), wrong suffix (both arbitrary length and fixed 15-byte), both prefix and suffix wrong at 45 bytes, valid proxy detection, and equivalence with a slow reference implementation. Constants are validated against specification literals.

| Finding | Severity | Description |
|---|---|---|
| A03-1 | INFO | No short-circuit on prefix failure before suffix hashing (intentional branchless design) |
| A03-2 | INFO | `unchecked` block is inert (no runtime arithmetic) |
| A03-3 | INFO | `memory-safe` correctness depends on constant invariants (well-designed coupling) |
| A03-4 | INFO | Detection limited to canonical ERC-1167 only (by design) |
| A03-5 | INFO | Hash comparison equivalent to direct byte comparison at these sizes |
| A03-6 | INFO | `address(0)` implementation is valid result (documented) |
