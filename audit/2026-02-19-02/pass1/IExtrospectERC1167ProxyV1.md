# Audit: IExtrospectERC1167ProxyV1.sol

**Auditor Agent:** A02
**Date:** 2026-02-19
**File:** `src/interface/IExtrospectERC1167ProxyV1.sol`

## Evidence of Thorough Reading

### Interface/Contract Name

- `IExtrospectERC1167ProxyV1` (line 11) -- declared as `interface`

### Functions

| Function Name | Line | Signature |
|---|---|---|
| `isERC1167Proxy` | 21 | `function isERC1167Proxy(address account) external view returns (bool result, address implementationAddress)` |

This is the only function in the interface.

### Types, Errors, and Constants Defined

None. The file defines no custom types (structs, enums), no errors, no events, and no constants. It is a pure interface with a single function declaration.

### File Structure Summary

- Lines 1-2: SPDX license and copyright
- Line 3: Pragma `^0.8.18`
- Lines 5-10: NatSpec title and notice for the interface
- Lines 11-22: Interface declaration with one function
- The interface is 23 lines total

## Findings

### A02-1: Interface signature diverges from library implementation signature (INFO)

**Severity:** INFO

**Location:** Line 21

**Description:**

The interface declares `isERC1167Proxy` as taking an `address account` parameter and being an `external view` function. The corresponding library implementation in `LibExtrospectERC1167Proxy.sol` (line 43) takes `bytes memory bytecode` and is `internal pure`.

This is by design -- the interface is intended for a contract that would externally call `EXTCODECOPY` (or `address.code`) on the given account, then pass the resulting bytecode to the library. However, this means that any implementor of this interface must:

1. Perform the `EXTCODECOPY`/code retrieval themselves.
2. Correctly pass the result to the library function.

There is no concrete implementation of this interface in the repository, so the bridge between `address -> bytecode retrieval -> library call` is entirely left to implementors. This is not a vulnerability in the interface itself, but is worth noting as it places a correctness burden on implementors.

**Recommendation:** This is informational. The design is reasonable for an extrospection pattern. No change needed.

### A02-2: NatSpec documents zero-address ambiguity but interface provides no mitigation (INFO)

**Severity:** INFO

**Location:** Lines 12-15

**Description:**

The NatSpec comment correctly warns callers: "The caller MUST check the result is true before using the implementation address, otherwise a valid proxy to `address(0)` and an invalid proxy will be indistinguishable."

This is an inherent limitation of the return type design (returning `(bool, address)` where the address is zero in the failure case). The documentation adequately warns about this. An alternative design could have used a custom error revert on failure, or returned only the address with a sentinel value, but the current `(bool, address)` pattern is idiomatic and the documentation is clear.

**Recommendation:** Informational only. The documentation is appropriate.

### A02-3: Interface uses floating pragma (INFO)

**Severity:** INFO

**Location:** Line 3

**Description:**

The file uses `pragma solidity ^0.8.18;`, which is a floating pragma allowing any compiler version from 0.8.18 up to (but not including) 0.9.0. For interfaces, this is standard and acceptable practice since interfaces contain no implementation logic that could be affected by compiler version differences. The concrete test file uses a pinned pragma (`=0.8.25`), which is appropriate.

**Recommendation:** No change needed. Floating pragmas on interfaces are standard practice.

### A02-4: No `view` enforcement mechanism at the interface level (INFO)

**Severity:** INFO

**Location:** Line 21

**Description:**

The function is declared as `external view`, which is correct since querying bytecode via `EXTCODECOPY` is a read-only operation. The `view` modifier is enforced by the Solidity compiler on any implementing contract, so this correctly prevents implementors from making state changes in their implementation of this function.

**Recommendation:** No change needed. This is correct.

## Summary

No security vulnerabilities were identified in `IExtrospectERC1167ProxyV1.sol`. The file is a minimal, well-documented Solidity interface consisting of a single function declaration. It contains no implementation logic, no assembly, no arithmetic, no state variables, and no reentrancy surface.

The interface correctly specifies:
- The `view` mutability (appropriate for bytecode extrospection)
- The `external` visibility (appropriate for an interface)
- The return type `(bool result, address implementationAddress)` with clear documentation about the zero-address edge case
- A reference to EIP-1167 in the NatSpec

All four findings are classified as INFO-level observations. There are no CRITICAL, HIGH, MEDIUM, or LOW findings.
