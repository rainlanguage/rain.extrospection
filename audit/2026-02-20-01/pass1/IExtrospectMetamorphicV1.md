# Audit: IExtrospectMetamorphicV1.sol

**Auditor:** A04
**File:** `src/interface/IExtrospectMetamorphicV1.sol`
**Date:** 2026-02-20
**Lines:** 17

---

## Evidence of Thorough Reading

### Interface Name

- `IExtrospectMetamorphicV1` (interface, line 11)

### Functions

| Function | Line |
|----------|------|
| `scanMetamorphicRisk(address account) external view returns (uint256 riskyOpcodes)` | 16 |

### Types, Errors, and Constants

None. This file defines a pure interface with no custom errors, no custom types, and no constants.

### Imports

None. The file has no import statements. The NatSpec comment on line 10 references `METAMORPHIC_OPS` from `EVMOpcodes.sol` by name, but does not import it.

### Summary of Contents

This is a 17-line Solidity interface declaring one `external view` function, `scanMetamorphicRisk`, which accepts an `address` and returns a `uint256` bitmap of reachable metamorphic risk opcodes found in the account's bytecode. The interface is purely declarative; the corresponding logic resides in `LibExtrospectMetamorphic.sol` (which in turn calls `LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode` and masks the result with `METAMORPHIC_OPS`). The file uses `pragma solidity ^0.8.25`, consistent with all other current source files in the project. There is no assembly, no arithmetic, no error handling, and no state mutation in the interface file itself.

---

## Findings

### A04-1: Missing documentation on EOA and non-existent account behavior — **LOW**

**Line:** 14–15

**Description:**

The NatSpec for `scanMetamorphicRisk` documents the return value as "Bitmap of reachable metamorphic opcodes. Zero if no metamorphic risk opcodes are reachable." It does not specify what the function returns when `account` is an EOA, a non-existent address, or any address with no deployed bytecode.

The reference implementation in `LibExtrospectMetamorphic.sol` delegates to `LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode`, which operates on `bytes memory bytecode`. For an EOA or non-existent account, `account.code` returns empty bytes, and the scan loop never executes, so the result is `0`. This is the correct and safe behavior, but it is undocumented.

A consumer reading only this interface could not determine the expected return value for a non-contract address. If the consumer is using the result to gate a security decision (e.g., "allow this address because `scanMetamorphicRisk` returned zero"), an address with no bytecode at scan time would also return zero. While returning zero for empty code is arguably the correct answer (no risky opcodes present), a malicious actor could pass an address that has no code yet but will later have code deployed via `CREATE2`. The interface documentation gives no guidance on this case, which is directly relevant to the metamorphic risk threat model.

**Recommendation:**

Add a NatSpec note clarifying behavior for empty-code accounts, for example:

```
/// @dev Returns `0` for accounts with no deployed bytecode (EOAs and
/// non-existent accounts). Callers should be aware that a zero return
/// does not prevent future code deployment at the same address.
```

---

### A04-2: Missing documentation on EOF bytecode behavior — **INFO**

**Line:** 12–16

**Description:**

The interface does not document how implementations should behave when `account` contains EOF-formatted bytecode (bytecode beginning with `0xEF00`, as specified by EIP-3540). The reference implementation in `LibExtrospectBytecode` calls `checkNotEOFBytecode()` and reverts with `EOFBytecodeNotSupported()` when EOF bytecode is encountered. This means the underlying `scanEVMOpcodesReachableInBytecode` call made by `LibExtrospectMetamorphic.scanMetamorphicRisk` will revert on EOF bytecode, but this is not communicated by the interface.

If an alternative implementation silently scans EOF bytecode (which has fundamentally different structure and no PUSH-inline data in the same sense), it could produce incorrect results. Callers cannot know from the interface alone that they should expect a revert on EOF bytecode.

**Recommendation:**

Add a NatSpec note indicating that implementations should revert on EOF-formatted bytecode, for example:

```
/// @dev Implementations SHOULD revert if `account` contains EOF-formatted
/// bytecode (beginning with `0xEF00`), as EOF has a fundamentally different
/// structure incompatible with this scanning algorithm.
```

---

### A04-3: The interface does not specify the precise set of opcodes covered by "metamorphic risk" — **INFO**

**Lines:** 6–16

**Description:**

The interface title comment (lines 6–10) states that the `METAMORPHIC_OPS` bitmap in `EVMOpcodes.sol` defines the set of risky opcodes, and the function-level NatSpec (line 14) refers to "metamorphic risk opcodes" without listing them. The file does not import `METAMORPHIC_OPS` or enumerate the covered opcodes (SELFDESTRUCT, DELEGATECALL, CALLCODE, CREATE, CREATE2).

This means an alternative implementor of `IExtrospectMetamorphicV1` has no normative source within the interface itself to determine which opcodes constitute "metamorphic risk." The reference to `EVMOpcodes.sol` in the NatSpec comment is informative but not binding, and since the interface has no import of `METAMORPHIC_OPS`, an alternative implementor could choose a different set.

In particular, callers may be surprised that `CALL` is not in `METAMORPHIC_OPS`. A contract with `DELEGATECALL` is flagged, but one with only `CALL` is not (even though `CALL` can invoke an intermediary that performs a metamorphic operation). The rationale for this design choice is not documented in the interface.

**Recommendation:**

Either enumerate the specific opcodes covered in the NatSpec of `scanMetamorphicRisk`, or import and reference `METAMORPHIC_OPS` directly so that the interface is self-contained with respect to what it scans for. Add a note explaining why `CALL` is excluded (i.e., indirect call chains are out of scope; only direct risk-bearing opcodes are flagged).

---

### A04-4: Interface has no implementation in this repository — **INFO**

**Line:** 11

**Description:**

`IExtrospectMetamorphicV1` is declared as an interface, but no contract in this repository implements it. `LibExtrospectMetamorphic.sol` provides a library with the corresponding logic, but it is not a contract implementing this interface. Any implementing contract would be external to this repository, meaning this interface serves solely as a specification for external consumers. The correctness of the function selector, ABI encoding, and the precise mapping of `LibExtrospectMetamorphic.scanMetamorphicRisk` to this interface's behavior cannot be verified from within this repository.

**Recommendation:**

No change required. Auditors of consuming codebases should verify that the implementing contract correctly calls `LibExtrospectMetamorphic.scanMetamorphicRisk` (or equivalent) and that the return value semantics match those documented here.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| A04-1 | LOW | Missing documentation on EOA and non-existent account behavior |
| A04-2 | INFO | Missing documentation on EOF bytecode behavior |
| A04-3 | INFO | Interface does not specify the precise set of opcodes covered |
| A04-4 | INFO | Interface has no implementation in this repository |

No CRITICAL, HIGH, or MEDIUM severity findings were identified. The file is a minimal, well-structured interface declaration. The primary actionable finding (A04-1, LOW) relates to undocumented behavior for empty-code accounts, which is directly relevant to the metamorphic risk threat model that this interface exists to address.
