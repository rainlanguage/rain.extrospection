# Audit: IExtrospectBytecodeV2.sol

**Auditor:** A01
**File:** `src/interface/IExtrospectBytecodeV2.sol`
**Date:** 2026-02-19

## Evidence of Thorough Reading

### Interface Name

- `IExtrospectBytecodeV2` (line 11)

### Functions

| Function Name | Line |
|---|---|
| `bytecode(address account) external view returns (bytes memory)` | 19 |
| `bytecodeHash(address account) external view returns (bytes32)` | 28 |
| `scanEVMOpcodesPresentInAccount(address account) external view returns (uint256 scan)` | 58 |
| `scanEVMOpcodesReachableInAccount(address account) external view returns (uint256 scan)` | 72 |

### Types, Errors, and Constants Defined

None. This file is a pure interface with no type definitions, custom errors, or constants.

### Summary of Contents

This is a Solidity interface (73 lines) that defines four `external view` functions for bytecode introspection of arbitrary EVM accounts. It is the V2 evolution of `IExtrospectBytecodeV1`, adding the `scanEVMOpcodesReachableInAccount` function (which scans only reachable opcodes, skipping unreachable regions after halting instructions). The interface is purely declarative; all logic resides in `LibExtrospectBytecode.sol`.

## Findings

### A01-1: `bytecodeHash` documentation inaccuracy for EOAs vs. non-existent accounts [LOW]

**Lines:** 26-27

**Description:**

The NatSpec documentation for `bytecodeHash` states:

> Will be `0` (NOT the hash of empty bytes) for non-contract accounts.

This is an oversimplification of `account.codehash` behavior per [EIP-1052](https://eips.ethereum.org/EIPS/eip-1052). The actual EVM semantics are:

- For **non-existent accounts** (never interacted with, zero balance, zero nonce, no code): `EXTCODEHASH` returns `0`.
- For **externally owned accounts (EOAs)** that exist (e.g., have a nonzero balance or nonce but no code): `EXTCODEHASH` returns the keccak256 hash of empty bytes (`0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfae8045e7a1010`).

The documentation says the return "Will be `0`... for non-contract accounts," which conflates these two distinct cases. An EOA with a balance is a "non-contract account" but its codehash is NOT `0` -- it is the keccak256 of empty bytes.

If an implementor or consumer relies on this documentation to distinguish contract accounts from non-contract accounts by checking `bytecodeHash(addr) == 0`, they would incorrectly classify funded EOAs as contracts (since the hash would be nonzero, being the hash of empty bytes, not zero).

**Recommendation:**

Clarify the documentation to distinguish the two cases:
- Non-existent accounts (no balance, no nonce, no code): returns `bytes32(0)`.
- Existing accounts with no code (e.g., funded EOAs): returns `keccak256("")` (`0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfae8045e7a1010`).

Or simplify to say: "Equivalent to `account.codehash`. See EIP-1052 for edge-case semantics regarding non-existent vs. empty-code accounts."

### A01-2: Missing documentation on EOF bytecode handling for scan functions [INFO]

**Lines:** 30-72

**Description:**

The `scanEVMOpcodesPresentInAccount` and `scanEVMOpcodesReachableInAccount` function documentation does not mention how EOF-formatted bytecode (beginning with `0xEF00`) is handled. Reviewing the implementation in `LibExtrospectBytecode.sol`, both `scanEVMOpcodesPresentInBytecode` (line 190) and `scanEVMOpcodesReachableInBytecode` (line 135) call `checkNotEOFBytecode()` which reverts with `EOFBytecodeNotSupported()` if EOF bytecode is encountered.

Since the EVM is actively adopting EOF (EIP-3540 and related EIPs), implementors of this interface should be aware that their implementations are expected to revert on EOF bytecode. This is not documented in the interface, which could lead to implementations that silently scan EOF bytecode incorrectly (since EOF has a fundamentally different code structure with no inline PUSH data the way legacy bytecode does).

**Recommendation:**

Add a NatSpec note to both scan functions indicating that EOF-formatted bytecode is not supported and implementations should revert when encountering it. This would align the interface specification with the reference implementation's behavior.

### A01-3: Typo in NatSpec documentation [INFO]

**Line:** 43

**Description:**

The word "prescence" on line 43 is a misspelling of "presence."

**Recommendation:**

Correct the spelling to "presence."

### A01-4: No specification of behavior for accounts with empty bytecode in scan functions [INFO]

**Lines:** 58, 72

**Description:**

The scan function specifications do not document the expected return value when the `account` parameter refers to an address with no deployed code (EOA or non-existent account). In this case, `account.code` returns empty bytes, and the scan should return `0` (no bits set). While this is the natural/correct behavior of the implementation (the loop body never executes for zero-length bytecode), making this explicit in the interface specification would reduce ambiguity for alternative implementors.

**Recommendation:**

Add a note: "Returns `0` if the account has no deployed bytecode."
