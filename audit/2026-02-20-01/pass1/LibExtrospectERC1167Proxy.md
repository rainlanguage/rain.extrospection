# Audit: LibExtrospectERC1167Proxy.sol

**Auditor Agent:** A08
**Date:** 2026-02-20
**File:** `src/lib/LibExtrospectERC1167Proxy.sol`

## Evidence of Thorough Reading

### Library Name

- `LibExtrospectERC1167Proxy` (line 38) — declared as `library`

### Functions

| Function | Line | Visibility | Mutability | Signature |
|---|---|---|---|---|
| `isERC1167Proxy` | 45 | `internal` | `pure` | `isERC1167Proxy(bytes memory bytecode) returns (bool result, address implementationAddress)` |

This is the only function in the library.

### Constants (all file-level, outside the library)

| Constant | Line | Type | Value / Formula |
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

### Errors, Events, Types

None defined anywhere in the file.

### Assembly Blocks

Three `assembly ("memory-safe")` blocks within `isERC1167Proxy`:
- Line 65-67: prefix hash comparison
- Line 74-76: suffix hash comparison
- Line 85-90: implementation address extraction

---

## Analysis

### ERC-1167 Specification Correctness

The EIP-1167 standard defines minimal proxy runtime bytecode as:

```
363d3d373d3d3d363d73 <20-byte-address> 5af43d82803e903d91602b57fd5bf3
```

- Prefix `363d3d373d3d3d363d73` = 10 bytes. `ERC1167_PREFIX` (line 7) matches.
- Suffix `5af43d82803e903d91602b57fd5bf3` = 15 bytes. `ERC1167_SUFFIX` (line 10) matches.
- Total length = 10 + 20 + 15 = 45 bytes. `ERC1167_PROXY_LENGTH` evaluates to 45. Correct.

The prefix ends with opcode `0x73` = `PUSH20`, which causes the EVM to treat the following 20 bytes as push data (the implementation address), after which execution resumes with the suffix. This is the canonical EIP-1167 structure.

The test file (`test/src/lib/LibExtrospectERC1167Proxy.isERC1167Proxy.t.sol`, line 141) independently asserts all constants against hardcoded hex literals, providing an independent check.

### Constant Arithmetic Verification

**`ERC1167_PREFIX_START = 0x20 = 32`**

A `bytes memory` variable pointer in Solidity points to a 32-byte length word followed immediately by data. Data begins at pointer + 32 = pointer + 0x20. The prefix is at data byte 0, so `keccak256(ptr + 32, 10)` hashes exactly the 10 prefix bytes. Correct.

**`ERC1167_SUFFIX_START = 0x20 + 45 - 15 = 62`**

Data layout: `[prefix(0..9)][addr(10..29)][suffix(30..44)]`. Suffix data-relative offset = 30. Memory offset = 32 + 30 = 62. Therefore `keccak256(ptr + 62, 15)` hashes exactly the 15 suffix bytes. Correct.

**`ERC1167_IMPLEMENTATION_ADDRESS_OFFSET = 10 + 20 = 30`**

Used as `mload(add(bytecode, 30))`. This reads 32 bytes starting at `ptr + 30`:
- `ptr+30` to `ptr+31`: last 2 bytes of the 32-byte length word (value `0x00, 0x2d` for length 45)
- `ptr+32` to `ptr+41`: prefix bytes (10 bytes)
- `ptr+42` to `ptr+61`: implementation address bytes (20 bytes)

The 32-byte `mload` result in big-endian order is `[len_tail(2)][prefix(10)][addr(20)]`. Masking with `type(uint160).max` (low 160 bits = low 20 bytes) isolates the address bytes. The 2 length word tail bytes and 10 prefix bytes fall in the high 12 bytes and are zeroed by the mask. Address extraction is correct.

### Memory Safety Analysis

`bytes memory bytecode` with `bytecode.length == 45` allocates: 32-byte length word + 45 data bytes = 77 bytes total from the pointer. All valid byte offsets from the pointer are `[0, 76]`.

| Assembly operation | Range read | In bounds? |
|---|---|---|
| `keccak256(ptr + 32, 10)` | `[ptr+32, ptr+41]` | Yes (max ptr+76) |
| `keccak256(ptr + 62, 15)` | `[ptr+62, ptr+76]` | Yes (exactly at limit) |
| `mload(ptr + 30)` | `[ptr+30, ptr+61]` | Yes (max ptr+76) |

The `keccak256` suffix read lands exactly at the last allocated byte (`ptr+76`). This is within bounds. All three `"memory-safe"` annotations are accurate.

### Bounds and Early-Return Logic

- Any bytecode not exactly 45 bytes returns `(false, address(0))` at line 52 before any assembly executes. This is the primary fast-path guard and eliminates all out-of-bounds concerns for non-matching lengths.
- The `if (result)` guard at line 80 ensures address extraction only runs when both prefix and suffix checks have passed. When `result` is `false`, `implementationAddress` is never written and remains `address(0)`.

### `unchecked` Scope

The entire function body is wrapped in `unchecked` (line 46). All arithmetic in the function body is either inside `assembly` blocks (which are inherently unchecked) or is a comparison (`bytecode.length != ERC1167_PROXY_LENGTH`). There are no Solidity-level arithmetic operations that could overflow or underflow. The `unchecked` wrapper has no effect on generated bytecode and introduces no risk.

### Branchless Design

After the prefix hash check sets `result = false`, execution continues to the suffix hash check rather than returning early. Both assembly blocks use `and(result, eq(...))` unconditionally. This is a deliberate design choice: it avoids conditional jumps to minimize branch misprediction on the success path. The extra `keccak256` on the failure path is a minor gas cost in exchange for predictable execution flow. This is not a security issue.

---

## Findings

No security findings.

The library correctly implements ERC-1167 minimal proxy detection. The prefix and suffix constants match the EIP-1167 specification. All constant arithmetic evaluates correctly. All three assembly memory reads are within the allocated region of the input `bytes memory` parameter. The `"memory-safe"` annotations are accurate. The address extraction via `mload` and `uint160` masking is correct and the length word tail bytes do not contaminate the result. Boundary conditions (wrong length, wrong prefix, wrong suffix, address(0) implementation) are all handled correctly.
