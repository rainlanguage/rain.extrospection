# Audit: IExtrospectBytecodeV1.sol

**Auditor Agent:** A05
**Date:** 2026-02-20
**File:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`

---

## Evidence of Thorough Reading

### Interface Name

- `IExtrospectBytecodeV1` — line 11, declared as `interface`
- Located in `src/interface/deprecated/`, indicating it is superseded by `IExtrospectBytecodeV2`

### Functions (with line numbers)

| Line | Signature | Mutability | Returns |
|------|-----------|------------|---------|
| 19 | `bytecode(address account)` | `external view` | `bytes memory` |
| 28 | `bytecodeHash(address account)` | `external view` | `bytes32` |
| 55 | `scanEVMOpcodesPresentInAccount(address account)` | `external view` | `uint256 scan` |

### Custom Types, Errors, and Constants

None. This is a pure interface; it defines no custom types, errors, events, or constants.

### Additional Structural Notes

- SPDX: `LicenseRef-DCL-1.0` (line 1)
- Copyright: 2020 Rain Open Source Software Ltd (line 2)
- Pragma: `^0.8.25` (line 3)
- `forge-lint` suppression on line 54 for `mixed-case-function` (covers `scanEVMOpcodesPresentInAccount`)
- File is 57 lines total
- No assembly, no state variables, no modifiers, no events, no errors, no imports
- V2 equivalent (`IExtrospectBytecodeV2`) adds `scanEVMOpcodesReachableInAccount` and formal `@param`/`@return` tags on `scanEVMOpcodesPresentInAccount`

---

## Findings

### A05-1: `bytecodeHash` NatSpec is factually incorrect per EIP-1052 — **LOW**

**Location:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`, lines 26–27

**Description:**

The `@return` NatSpec for `bytecodeHash` states:

> Will be `0` (NOT the hash of empty bytes) for non-contract accounts.

This is inaccurate. The EVM opcode `EXTCODEHASH` (which `account.codehash` maps to) distinguishes between two categories of accounts that have no deployed code:

- **Non-existent accounts** (zero balance, zero nonce, no code): `EXTCODEHASH` returns `0x0`.
- **Existing EOAs** (non-zero balance or nonce, but no code): `EXTCODEHASH` returns `keccak256("")` = `0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfab8045d85a470`.

This behavior is specified in [EIP-1052](https://eips.ethereum.org/EIPS/eip-1052). The documentation's blanket claim that the return will be `0` for "non-contract accounts" conflates these two cases. Any caller using `bytecodeHash` to distinguish contract accounts from non-contract accounts by checking for a zero return value will fail for funded EOAs, which return a non-zero hash. An implementor following this NatSpec literally may also produce a non-conformant implementation.

The V2 equivalent (`IExtrospectBytecodeV2`) has corrected this documentation to accurately reflect EIP-1052 behavior.

**Impact:** Callers or implementors relying on the documented behavior for non-existent vs. existing EOA discrimination will receive incorrect results without any indication that the documentation is wrong. Downstream security logic that uses `bytecodeHash == 0` to gate on "no contract" could be bypassed by a funded EOA.

**Recommendation:** Update the `@return` NatSpec to reflect EIP-1052 behavior, for example:

```
/// @return The hash of the bytecode of `account`. Will be `0` for accounts
/// that do not exist (no balance, nonce, or code), per EIP-1052. Will be
/// `keccak256("")` for existing accounts with no code (e.g. funded EOAs).
```

---

### A05-2: `scanEVMOpcodesPresentInAccount` specifies no revert conditions, but the reference implementation reverts on EOF bytecode — **LOW**

**Location:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`, lines 30–55

**Description:**

The NatSpec for `scanEVMOpcodesPresentInAccount` is extensive (24 lines) and documents PUSH-skip behavior in detail, but contains no `@return` tag and no documentation of any revert conditions.

The reference implementation in `LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode` (line 210 in `LibExtrospectBytecode.sol`) calls `checkNotEOFBytecode` before scanning, which reverts with `EOFBytecodeNotSupported()` if the first two bytes of bytecode are `0xEF00`. This means any conforming implementation of this interface that defers to the library will revert for EOF-formatted bytecode.

Because the interface does not document this, a caller has no way to know:

1. That the function can revert at all.
2. Under what conditions it reverts.
3. Whether a different implementation of this interface might silently scan EOF bytecode instead of reverting.

This creates an undocumented behavioral contract that callers must discover by reading implementation source rather than the interface specification. It also means implementations are free to diverge — one might revert, another might succeed with potentially meaningless results — with no violation of the interface specification.

**Impact:** Callers that pass addresses whose bytecode has been upgraded to EOF format will receive unexpected reverts with no documented explanation. The interface provides no specification for implementors about what to do with EOF bytecode, allowing interoperability failures between different implementations.

**Recommendation:** Add explicit documentation of revert behavior:

```
/// @dev MUST revert if the account contains EOF-formatted bytecode
/// (first two bytes are `0xEF00`). EOF bytecode requires a different
/// scanner and is not supported by this function.
```

---

### A05-3: No deprecation notice within the interface file itself — **INFO**

**Location:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`, lines 5–10

**Description:**

The interface is placed in a `deprecated/` directory, signalling that it should not be used for new integrations. However, the NatSpec within the file itself contains no `@dev` or `@notice` tag indicating deprecation, no statement that `IExtrospectBytecodeV2` is the current version, and no reason for deprecation.

A consumer discovering this interface via a documentation generator (which renders NatSpec without directory context), a dependency, or a package registry would have no indication that a newer version exists or that this interface is no longer maintained. This could lead to:

- New implementations against V1 that miss `scanEVMOpcodesReachableInAccount` from V2.
- Integrators developing against an interface that may be removed or stop receiving security-relevant updates.

**Recommendation:** Add a top-level deprecation notice to the interface NatSpec:

```solidity
/// @dev DEPRECATED. Use `IExtrospectBytecodeV2` instead.
/// V2 adds `scanEVMOpcodesReachableInAccount` and corrects documentation.
```

---

### A05-4: `scanEVMOpcodesPresentInAccount` lacks `@param` and `@return` NatSpec tags — **INFO**

**Location:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`, lines 30–55

**Description:**

All three functions in this interface have `@param account` and `@return` tags for `bytecode` and `bytecodeHash`. However, `scanEVMOpcodesPresentInAccount` — despite having the most extensive documentation (24 lines describing the bitmap encoding and PUSH-skip behavior) — has neither a formal `@param` tag nor a `@return` tag.

The V2 interface adds both:

```
/// @param account The account to scan for opcodes.
/// @return scan A single `uint256` where each bit represents the presence of
/// an opcode in the source bytecode.
```

The absence of these tags means tooling that renders NatSpec (e.g., `forge doc`, IDE hovers) will omit parameter and return value documentation for this function, reducing clarity for callers.

**Recommendation:** Add `@param account` and `@return scan` tags, consistent with V2.

---

No additional security findings beyond documentation and specification issues. This file contains no assembly, no arithmetic, no state mutations, no access control, and no error handling logic — it is a pure interface declaration. All security-relevant behavior must be addressed in implementations.
