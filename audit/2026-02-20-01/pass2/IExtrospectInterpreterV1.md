# Pass 2: Test Coverage — A03 — IExtrospectInterpreterV1

## Evidence of Thorough Reading

**Source file:** `src/interface/IExtrospectInterpreterV1.sol`

- Interface: `IExtrospectInterpreterV1` (line 62)
- Function: `scanOnlyAllowedInterpreterEVMOpcodes(address interpreter) external view returns (bool)` (line 75)
- Constant `NON_STATIC_OPS` (lines 25-35): 11 bits
- Constant `INTERPRETER_DISALLOWED_OPS` (lines 38-55): 15 bits

**Test file:** `test/src/interface/IExtrospectInterpreterV1.t.sol`

Test functions: `testNonStaticOps`, `testInterpreterDisallowedOps`, `testInterpreterDisallowedOpsIsSupersetOfNonStaticOps`, `testNonStaticOpsIndividualBits`, `testNonStaticOpsExclusions`, `testNonStaticOpsPopcount`, `testInterpreterDisallowedOpsPopcount`

## Findings

### A03-1: No individual-bit assertions for `INTERPRETER_DISALLOWED_OPS` — **LOW**

`testNonStaticOpsIndividualBits()` asserts each of the 11 `NON_STATIC_OPS` bits individually. No equivalent test exists for `INTERPRETER_DISALLOWED_OPS`. The four additional opcodes (SLOAD, TLOAD, DELEGATECALL, CALLCODE) are covered only by the full-equality check and popcount.

### A03-2: No exclusion test for `INTERPRETER_DISALLOWED_OPS` — **LOW**

`testNonStaticOpsExclusions()` verifies safe opcodes are absent from `NON_STATIC_OPS`. No equivalent test exists for `INTERPRETER_DISALLOWED_OPS`. No assertion that STATICCALL, RETURN, REVERT, or arithmetic opcodes are absent.

### A03-3: `testNonStaticOpsExclusions` does not check that CALLCODE is absent from `NON_STATIC_OPS` — **LOW**

The exclusion test checks SLOAD, TLOAD, and DELEGATECALL are not in `NON_STATIC_OPS`, but omits CALLCODE (0xF2).

### A03-4: `scanOnlyAllowedInterpreterEVMOpcodes` has no test of any kind — **MEDIUM**

The sole function declared in `IExtrospectInterpreterV1` has zero test coverage. There is no concrete implementation in this repository and no test exercises the function's behaviour.
