# Test Coverage Audit -- Interfaces

## A01: `src/interface/IExtrospectBytecodeV2.sol`

### Source File Summary

Pure interface (73 lines) with 4 external function signatures:
- `bytecode(address)` (line 19)
- `bytecodeHash(address)` (line 28)
- `scanEVMOpcodesPresentInAccount(address)` (line 58)
- `scanEVMOpcodesReachableInAccount(address)` (line 72)

### Evidence of Thorough Reading

No implementation contract in this repo. The underlying library functions (`LibExtrospectBytecode`) have dedicated test files with fuzz coverage.

### Findings

#### A01-P2-1 [INFO] No implementation of IExtrospectBytecodeV2 in this repository

The interface is defined but no contract implements it in this repo. The library functions it wraps are tested directly. The interface itself has no logic to test.

---

## A02: `src/interface/IExtrospectERC1167ProxyV1.sol`

### Source File Summary

Pure interface (21 lines) with 1 external function signature:
- `isERC1167Proxy(address)` (line 20)

### Evidence of Thorough Reading

No implementation in this repo. The underlying `LibExtrospectERC1167Proxy.isERC1167Proxy` is tested directly.

### Findings

#### A02-P2-1 [INFO] No implementation of IExtrospectERC1167ProxyV1 in this repository

Same as A01-P2-1 -- interface only, no implementation to test.

---

## A03: `src/interface/IExtrospectInterpreterV1.sol`

### Source File Summary

Interface (72 lines) with:
- `NON_STATIC_OPS` constant (lines 20-25): bitmap of opcodes that violate EIP-214 static context
- `INTERPRETER_DISALLOWED_OPS` constant (lines 30-40): bitmap of opcodes disallowed in interpreters
- `scanOnlyAllowedInterpreterEVMOpcodes(address)` function (line 71)

### Evidence of Thorough Reading

Grepped entire test directory for references to `IExtrospectInterpreterV1`, `NON_STATIC_OPS`, `INTERPRETER_DISALLOWED_OPS`, and `scanOnlyAllowedInterpreterEVMOpcodes`. No matches found.

### Findings

#### A03-P2-1 [HIGH] Security-critical bitmap constants have zero test coverage

`NON_STATIC_OPS` and `INTERPRETER_DISALLOWED_OPS` are security-critical constants that define which EVM opcodes are forbidden for interpreter safety validation. Neither constant is imported, referenced, or tested anywhere in the repository.

These bitmaps encode the security policy for interpreter contracts. A single bit error could:
- Silently permit a dangerous opcode like `SELFDESTRUCT` or `DELEGATECALL`
- Incorrectly block a safe opcode, causing valid interpreters to be rejected

No contract implements `IExtrospectInterpreterV1` or `scanOnlyAllowedInterpreterEVMOpcodes` in this repo, meaning the entire interpreter safety validation feature is untested.

**Recommendation:** Add a test that validates both constants bit-by-bit against their expected opcode lists:
```solidity
// Verify NON_STATIC_OPS includes exactly: CREATE, CREATE2, LOG0-4, SSTORE, SELFDESTRUCT
uint256 expected = (1 << EVM_OP_CREATE) | (1 << EVM_OP_CREATE2) | ...;
assertEq(NON_STATIC_OPS, expected);
```

---

## A04: `src/interface/deprecated/IExtrospectBytecodeV1.sol`

### Source File Summary

Deprecated interface (48 lines) with 3 external function signatures:
- `bytecode(address)` (line 17)
- `bytecodeHash(address)` (line 27)
- `scanEVMOpcodesPresentInAccount(address)` (line 47)

### Evidence of Thorough Reading

Deprecated -- superseded by V2 which adds `scanEVMOpcodesReachableInAccount`. No implementation in this repo.

### Findings

#### A04-P2-1 [INFO] Deprecated interface with no implementation

V1 is superseded by V2. No tests needed for the interface itself.
