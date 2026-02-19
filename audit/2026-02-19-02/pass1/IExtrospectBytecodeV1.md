# Audit: IExtrospectBytecodeV1.sol

**Auditor Agent:** A04
**Date:** 2026-02-19
**File:** `/Users/thedavidmeister/Code/rain.extrospection/src/interface/deprecated/IExtrospectBytecodeV1.sol`

## Evidence of Thorough Reading

### Interface Name
- `IExtrospectBytecodeV1` (line 11), declared as `interface`

### Functions (with line numbers)
1. `bytecode(address account) external view returns (bytes memory)` -- line 19
2. `bytecodeHash(address account) external view returns (bytes32)` -- line 28
3. `scanEVMOpcodesPresentInAccount(address account) external view returns (uint256 scan)` -- line 55

### Types, Errors, and Constants Defined
- None. This file defines no custom types, errors, or constants. It is a pure interface definition containing only function signatures and NatSpec documentation.

### Additional Observations
- The file is 56 lines long.
- SPDX license identifier: `LicenseRef-DCL-1.0`
- Pragma: `^0.8.18`
- The file resides in a `deprecated/` directory, indicating it is no longer the current version.
- The interface has a forge-lint suppression comment on line 54 for mixed-case function naming (`scanEVMOpcodesPresentInAccount`).

## Findings

### A04-1: NatSpec for `bytecodeHash` incorrectly documents return for non-contract accounts

**Severity:** LOW

**File:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`, lines 26-27

**Description:**
The NatSpec for `bytecodeHash` states:

> Will be `0` (NOT the hash of empty bytes) for non-contract accounts.

This is misleading. The behavior of `account.codehash` (which the function is documented as equivalent to) is nuanced:

- For an account that **has never existed** (no balance, no nonce, no code), `EXTCODEHASH` returns `0x0`.
- For an **externally owned account (EOA)** that exists (has balance or nonce but no code), `EXTCODEHASH` returns `keccak256("")` which is `0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfab8045d85a470`, **NOT** `0`.

Per [EIP-1052](https://eips.ethereum.org/EIPS/eip-1052), `EXTCODEHASH` returns `0` only for accounts that do not exist (as defined by EIP-161: accounts with no code, no nonce, and zero balance). For existing EOAs (e.g., an address that has received ETH), it returns the keccak256 of empty bytes.

The NatSpec says "Will be `0` ... for non-contract accounts" which conflates non-existent accounts with existing EOAs. An implementor following this documentation literally may produce an incorrect implementation or callers may have incorrect assumptions about the return value for funded EOAs.

**Recommendation:**
Clarify the documentation to distinguish between non-existent accounts (returns `0x0`) and existing non-contract accounts / EOAs (returns `keccak256("")`). For example:

```
/// @return The hash of the bytecode of `account`. Will be `0` for accounts
/// that do not exist (no balance, nonce, or code). Will be keccak256 of
/// empty bytes for existing externally-owned accounts (accounts with no
/// code but nonzero balance or nonce).
```

---

### A04-2: NatSpec for `bytecode` uses ambiguous "0 length" phrasing

**Severity:** INFO

**File:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`, lines 17-18

**Description:**
The return documentation states:

> Will be `0` length for non-contract accounts.

The phrasing "`0` length" could be slightly clearer. The backtick-formatted `0` could be read as the literal value zero rather than as "zero-length." This is a minor clarity issue. Additionally, as with `bytecodeHash`, the term "non-contract accounts" is imprecise -- `account.code` returns empty bytes for both non-existent accounts and existing EOAs alike, so the documentation is functionally correct here, but the terminology could be more precise.

**Recommendation:**
Consider clarifying to "Will be empty bytes (zero length) for externally-owned accounts and accounts that do not exist."

---

### A04-3: Interface is in `deprecated/` directory but has no deprecation notice or migration guidance

**Severity:** INFO

**File:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`

**Description:**
The interface resides in a `deprecated/` directory, which indicates it should no longer be used for new implementations. However, the file itself contains no `@deprecated` NatSpec tag, no comments indicating why it was deprecated, and no pointer to a replacement interface. An implementor or consumer discovering this interface might not notice the directory path and could unknowingly depend on a deprecated interface.

**Recommendation:**
Add a `@notice` or `@dev` deprecation note within the file itself, including a reference to whatever replaced this interface (if applicable).

---

### A04-4: `scanEVMOpcodesPresentInAccount` specification contains a typo

**Severity:** INFO

**File:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`, line 43

**Description:**
Line 43 contains the word "prescence" which should be "presence":

> ...discovering the prescence of a specific opcode.

This is purely cosmetic and has no security impact.

**Recommendation:**
Correct the typo: "prescence" -> "presence".

---

### A04-5: Interface does not specify behavior for precompile addresses

**Severity:** LOW

**File:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`

**Description:**
The interface functions `bytecode`, `bytecodeHash`, and `scanEVMOpcodesPresentInAccount` all accept an `address account` parameter but do not document what happens when a precompile address (e.g., `0x01` through `0x09` on Ethereum mainnet, or chain-specific precompiles) is passed.

For precompiles:
- `account.code` returns empty bytes (they have no deployed bytecode).
- `account.codehash` behavior varies: on some chains/EVM versions, precompiles may return `keccak256("")` or `0x0` depending on whether the precompile is considered "existing" in the state trie.

Implementors relying on this interface to detect contract vs. non-contract addresses could be confused by precompile behavior, as precompiles are functional contracts that execute code but have no retrievable bytecode.

**Recommendation:**
Add a note documenting the expected behavior for precompile addresses, or explicitly state that precompile addresses are out of scope.

---

### A04-6: No specification of revert conditions for `scanEVMOpcodesPresentInAccount`

**Severity:** INFO

**File:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`, line 55

**Description:**
The library implementation (`LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode`) includes an EOF bytecode check that reverts with `EOFBytecodeNotSupported()` if the bytecode starts with `0xEF00`. However, the interface's NatSpec for `scanEVMOpcodesPresentInAccount` does not document any revert conditions. An implementor of this interface might omit the EOF check, or a consumer might not expect reverts.

The same concern does not apply to `bytecode` and `bytecodeHash` as those are simple wrappers around EVM opcodes that should never revert for any input.

**Recommendation:**
Document that implementations SHOULD or MUST revert for EOF-formatted bytecode, or note that EOF handling is implementation-defined.
