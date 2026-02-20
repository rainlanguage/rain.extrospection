# Audit: IExtrospectBytecodeV2.sol

**Auditor:** A01
**File:** `src/interface/IExtrospectBytecodeV2.sol`
**Date:** 2026-02-20

## Evidence of Thorough Reading

### Interface Name

- `IExtrospectBytecodeV2` (line 11)

### Functions

| Function Name | Line |
|---|---|
| `bytecode(address account) external view returns (bytes memory)` | 19 |
| `bytecodeHash(address account) external view returns (bytes32)` | 29 |
| `scanEVMOpcodesPresentInAccount(address account) external view returns (uint256 scan)` | 59 |
| `scanEVMOpcodesReachableInAccount(address account) external view returns (uint256 scan)` | 73 |

### Types, Errors, and Constants Defined

None. This file is a pure interface with no type definitions, custom errors, or constants.

### forge-lint Suppressions

- Line 58: `//forge-lint: disable-next-line(mixed-case-function)` — suppresses camelCase warning for `scanEVMOpcodesPresentInAccount`.
- Line 72: `//forge-lint: disable-next-line(mixed-case-function)` — suppresses camelCase warning for `scanEVMOpcodesReachableInAccount`.

### Summary of Contents

This is a 74-line Solidity interface that declares four `external view` functions for bytecode introspection of arbitrary EVM accounts. It is the V2 successor to the deprecated `IExtrospectBytecodeV1`, adding `scanEVMOpcodesReachableInAccount` (which skips unreachable bytecode regions after halting opcodes). The interface is purely declarative; all logic is in `LibExtrospectBytecode.sol`.

### Comparison with Previous Audit (2026-02-19-02)

The previous audit of this file (session 2026-02-19-02) raised four findings. The current file resolves one of them:

- **A01-1 (bytecodeHash documentation inaccuracy):** RESOLVED. Lines 26-28 now correctly state "Per EIP-1052, will be `0` for non-existent accounts and `keccak256(\"\")` for existing accounts with no code (e.g. funded EOAs)." This accurately distinguishes the two cases.
- **A01-2 (no EOF documentation in scan functions):** Still present — see finding A01-1 below.
- **A01-3 (typo "prescence"):** Not present in this file — the word does not appear.
- **A01-4 (no spec for empty bytecode input):** Still present — see finding A01-2 below.

## Findings

### A01-1: Scan functions do not specify EOF bytecode behavior in NatSpec — **LOW**

**Lines:** 31-59, 61-73

**Description:**

Both `scanEVMOpcodesPresentInAccount` and `scanEVMOpcodesReachableInAccount` lack any documentation of their behavior when the target account contains EOF-formatted bytecode (bytecode beginning with the magic bytes `0xEF00`, per EIP-3540). The reference implementation in `LibExtrospectBytecode.sol` handles this case by reverting with the custom error `EOFBytecodeNotSupported()`, called via `checkNotEOFBytecode()` at the top of both `scanEVMOpcodesPresentInBytecode` and `scanEVMOpcodesReachableInBytecode`.

This omission has two concrete risks:

1. **Alternative implementors** of `IExtrospectBytecodeV2` may silently scan EOF bytecode rather than reverting, producing incorrect results. EOF has a structured container format that is fundamentally incompatible with the linear PUSH-aware scan described in the NatSpec. Treating EOF sections as legacy opcodes would yield arbitrary false positives.

2. **Callers** are not warned that these functions may revert unexpectedly on contracts deployed with EOF bytecode. As EOF adoption grows (it is expected to be activated in a future EVM upgrade), this becomes an increasingly practical concern.

Since the interface defines the behavioral contract that implementations must satisfy, the absence of this specification is a meaningful gap — not merely cosmetic.

**Recommendation:**

Add a NatSpec `@dev` note to both scan functions specifying that EOF-formatted bytecode (beginning with `0xEF00`) is not supported and that implementations MUST revert when such bytecode is encountered. For example:

```solidity
/// @dev Reverts with `EOFBytecodeNotSupported()` if the account's bytecode
/// begins with the EOF magic bytes `0xEF00`. EOF bytecode has a structured
/// container format incompatible with the legacy linear scan algorithm.
```

### A01-2: Scan functions do not specify return value for accounts with no deployed bytecode — **INFO**

**Lines:** 55-57, 69-71

**Description:**

The `@return` documentation for both scan functions states that the return value is "A single `uint256` where each bit represents the presence of an opcode in the source bytecode," but does not explicitly define the return value when `account` is an EOA or a non-existent address (both of which have zero-length bytecode via `account.code`).

In the reference implementation, calling either scan function on such an address results in a return value of `0` (no bits set), because the inner loop never executes on zero-length input. While `0` is the natural result and cannot be confused with a valid scan (which would set at least one bit if any opcode exists), alternative implementations may behave differently — for example, returning a sentinel value or reverting.

Making the zero-bytecode case explicit in the interface specification would remove ambiguity for implementors and callers who need to distinguish "no code" from "code with no detectable opcodes" (which is impossible in practice for non-empty legacy bytecode, since every byte is an opcode, but possible in theory).

**Recommendation:**

Add a sentence to the `@return` documentation for both scan functions: "Returns `0` if the account has no deployed bytecode (e.g., EOAs and non-existent accounts)."
