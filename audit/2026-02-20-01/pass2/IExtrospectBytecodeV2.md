# Pass 2: Test Coverage — A01 — IExtrospectBytecodeV2

## Evidence of Thorough Reading

**Interface:** `IExtrospectBytecodeV2` (line 11)

**Functions:**

| Line | Signature |
|------|-----------|
| 19 | `bytecode(address account) external view returns (bytes memory)` |
| 29 | `bytecodeHash(address account) external view returns (bytes32)` |
| 59 | `scanEVMOpcodesPresentInAccount(address account) external view returns (uint256 scan)` |
| 73 | `scanEVMOpcodesReachableInAccount(address account) external view returns (uint256 scan)` |

No test file exists for `IExtrospectBytecodeV2`. No contract in `src/` implements it. All library-level functions are well tested but no account-level interface function is tested.

## Findings

### A01-1: No test file exists for `IExtrospectBytecodeV2` — **HIGH**

No `test/src/interface/IExtrospectBytecodeV2.t.sol` or equivalent. All four interface functions have zero test coverage through the interface type.

### A01-2: `bytecode` — not tested for any account variant — **HIGH**

No test verifies non-existent address, funded EOA, or deployed contract returning correct bytecode. The `account.code` lookup is entirely untested.

### A01-3: `bytecodeHash` — EIP-1052 edge cases not tested — **HIGH**

NatSpec documents EIP-1052 semantics (non-existent=0, funded EOA=keccak256(""), contract=hash). No test exercises any of these three cases.

### A01-4: `scanEVMOpcodesPresentInAccount` — no account-level test — **MEDIUM**

The underlying library function is well tested. The interface function adds the `account.code` fetch step which is untested.

### A01-5: `scanEVMOpcodesReachableInAccount` — no account-level test — **MEDIUM**

Same gap as A01-4 for the V2-new reachable scan function.

### A01-6: No concrete implementation of `IExtrospectBytecodeV2` exists in `src/` — **INFO**

The interface is defined but no contract implements it. All above findings are a direct consequence.
