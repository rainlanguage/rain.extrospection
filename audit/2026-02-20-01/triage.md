# Audit Triage: 2026-02-20-01

## Pass 0: Process Review

| ID | Severity | Finding | Status |
|---|---|---|---|
| P0-1 | LOW | CLAUDE.md pragma version is inaccurate (`^0.8.18` stated for interfaces, but all source files use `^0.8.25`) | FIXED |
| P0-2 | LOW | CLAUDE.md missing `rain.math.binary` dependency | FIXED |
| P0-3 | LOW | CLAUDE.md missing `LibExtrospectMetamorphic` in core libraries documentation | FIXED |

## Pass 1: Security

| ID | Severity | Finding | Status |
|---|---|---|---|
| A01-1 | LOW | `IExtrospectBytecodeV2`: Scan functions do not specify EOF bytecode revert behavior in NatSpec | FIXED — interfaces removed |
| A04-1 | LOW | `IExtrospectMetamorphicV1`: Missing documentation on EOA and non-existent account behavior for `scanMetamorphicRisk` | FIXED — interfaces removed |
| A05-1 | LOW | `IExtrospectBytecodeV1`: `bytecodeHash` NatSpec is factually incorrect per EIP-1052 for funded EOAs | FIXED — interfaces removed |
| A05-2 | LOW | `IExtrospectBytecodeV1`: `scanEVMOpcodesPresentInAccount` specifies no revert conditions but implementation reverts on EOF bytecode | FIXED — interfaces removed |

## Pass 2: Test Coverage

| ID | Severity | Finding | Status |
|---|---|---|---|
| A01-1 | HIGH | `IExtrospectBytecodeV2`: No test file exists for `IExtrospectBytecodeV2` -- all four interface functions have zero test coverage through the interface type | FIXED — interfaces removed |
| A01-2 | HIGH | `IExtrospectBytecodeV2`: `bytecode` not tested for any account variant (non-existent address, funded EOA, deployed contract) | FIXED — interfaces removed |
| A01-3 | HIGH | `IExtrospectBytecodeV2`: `bytecodeHash` EIP-1052 edge cases (non-existent=0, funded EOA=keccak256(""), contract=hash) not tested | FIXED — interfaces removed |
| A01-4 | MEDIUM | `IExtrospectBytecodeV2`: `scanEVMOpcodesPresentInAccount` has no account-level test (only library tested) | FIXED — interfaces removed |
| A01-5 | MEDIUM | `IExtrospectBytecodeV2`: `scanEVMOpcodesReachableInAccount` has no account-level test (only library tested) | FIXED — interfaces removed |
| A03-1 | LOW | `IExtrospectInterpreterV1`: No individual-bit assertions for `INTERPRETER_DISALLOWED_OPS` (only full-equality and popcount) | FIXED |
| A03-2 | LOW | `IExtrospectInterpreterV1`: No exclusion test for `INTERPRETER_DISALLOWED_OPS` (no check that STATICCALL, RETURN, REVERT, etc. are absent) | FIXED |
| A03-3 | LOW | `IExtrospectInterpreterV1`: `testNonStaticOpsExclusions` does not check that CALLCODE (0xF2) is absent from `NON_STATIC_OPS` | FIXED |
| A03-4 | MEDIUM | `IExtrospectInterpreterV1`: `scanOnlyAllowedInterpreterEVMOpcodes` has zero test coverage (no concrete implementation, no test) | FIXED — interfaces removed (function no longer exists) |
| A04-1 | MEDIUM | `IExtrospectMetamorphicV1`: No end-to-end test of `scanMetamorphicRisk(address)` through the interface | FIXED — interfaces removed |
| A04-2 | LOW | `IExtrospectMetamorphicV1`: `testMetamorphicOpsExclusions` checks only 3 of 251 non-member opcode bytes | FIXED |
| A05-2 | LOW | `IExtrospectBytecodeV1`: `bytecodeHash` NatSpec documents incorrect return value for funded EOAs -- no test confirms EIP-1052 distinction for V1 | FIXED — interfaces removed |
| A06-1 | LOW | `EVMOpcodes`: No exclusion tests for `HALTING_BITMAP` (e.g., JUMPI 0x57 not tested absent, JUMPDEST 0x5B not tested absent) | FIXED |
| A07-1 | LOW | `LibExtrospectBytecode`: No explicit unit test for PUSH0 (0x5F) boundary in either scan function | FIXED |
| A09-1 | LOW | `LibExtrospectMetamorphic`: `checkNotMetamorphic` missing individual revert tests for CALLCODE and CREATE | FIXED |
| A09-2 | LOW | `LibExtrospectMetamorphic`: `checkNotMetamorphic` revert tests use bare `vm.expectRevert()` without verifying `Metamorphic` error type or `riskyOpcodes` parameter | FIXED |
| A09-3 | LOW | `LibExtrospectMetamorphic`: `checkNotMetamorphic` has no fuzz test (unlike `scanMetamorphicRisk` which has a differential oracle fuzz test) | FIXED |

## Pass 3: Documentation

| ID | Severity | Finding | Status |
|---|---|---|---|
| A01-1 | MEDIUM | `IExtrospectBytecodeV2`: `scanEVMOpcodesPresentInAccount` missing revert condition for EOF bytecode in NatSpec | FIXED — interfaces removed |
| A01-2 | MEDIUM | `IExtrospectBytecodeV2`: `scanEVMOpcodesReachableInAccount` missing revert condition for EOF bytecode in NatSpec | FIXED — interfaces removed |
| A01-3 | LOW | `IExtrospectBytecodeV2`: `bytecode` `@return` uses backtick-quoted `0` to describe a zero-length array (should say "empty") | FIXED — interfaces removed |
| A03-1 | LOW | `IExtrospectInterpreterV1`: `NON_STATIC_OPS` `@dev` is a bare URL with no descriptive prose | FIXED |
| A03-2 | LOW | `IExtrospectInterpreterV1`: `NON_STATIC_OPS` cites EIP-214 without disclosing TSTORE extension (EIP-1153/Cancun) | FIXED |
| A03-3 | LOW | `IExtrospectInterpreterV1`: Inline comment on line 53 is factually inaccurate ("static list allows 0 value calls" -- it does not) | FIXED |
| A03-4 | LOW | `IExtrospectInterpreterV1`: `INTERPRETER_DISALLOWED_OPS` `@dev` uses "allowlist" to describe a disallowed-ops bitmap | FIXED |
| A04-1 | LOW | `IExtrospectMetamorphicV1`: Missing `@notice` tag on `scanMetamorphicRisk` | FIXED — interfaces removed |
| A04-2 | LOW | `IExtrospectMetamorphicV1`: Return value description inaccurate for empty-code accounts (CREATE2 future deployment risk) | FIXED — interfaces removed |
| A04-3 | LOW | `IExtrospectMetamorphicV1`: No documentation of revert on EOF bytecode | FIXED — interfaces removed |
| A05-1 | LOW | `IExtrospectBytecodeV1`: `bytecodeHash` return NatSpec inaccurately describes behavior for funded EOAs | FIXED — interfaces removed |
| A05-2 | MEDIUM | `IExtrospectBytecodeV1`: `scanEVMOpcodesPresentInAccount` has no `@param` or `@return` NatSpec tags (24 lines of prose but no formal tags) | FIXED — interfaces removed |
| A07-2 | LOW | `LibExtrospectBytecode`: `scanEVMOpcodesReachableInBytecode` NatSpec does not document the halting-and-resume algorithm | FIXED |

## Pass 4: Code Quality

| ID | Severity | Finding | Status |
|---|---|---|---|
| A01-1 | LOW | `IExtrospectBytecodeV2`: Inconsistent named vs unnamed return parameters across the four interface functions | FIXED — interfaces removed |
| A01-2 | LOW | `IExtrospectBytecodeV2`: CLAUDE.md documents `^0.8.18` pragma for interfaces but all interfaces use `^0.8.25` | FIXED — interfaces removed; CLAUDE.md updated |
| A03-1 | LOW | `IExtrospectInterpreterV1`: File-level constants (`NON_STATIC_OPS`, `INTERPRETER_DISALLOWED_OPS`) defined inside an interface file, unlike all other interfaces | FIXED — constants moved to EVMOpcodes.sol |
| A03-2 | LOW | `IExtrospectInterpreterV1`: `@dev` comment on `INTERPRETER_DISALLOWED_OPS` uses "allowlist" for a disallowed-ops bitmap | FIXED |
| A03-3 | LOW | `IExtrospectInterpreterV1`: Inline comment on line 53 is factually inaccurate ("static list allows 0 value calls") | FIXED |
| A04-1 | LOW | `IExtrospectMetamorphicV1`: Return value semantics ambiguous for zero-code accounts (indistinguishable from scanned contract with no risky opcodes) | FIXED — interfaces removed |
| A05-1 | LOW | `IExtrospectBytecodeV1`: Intra-file NatSpec style inconsistency -- `scanEVMOpcodesPresentInAccount` breaks the `@param`/`@return` pattern | FIXED — interfaces removed |
| A05-2 | LOW | `IExtrospectBytecodeV1`: No deprecation notice within the file itself (NatSpec identical to V2) | FIXED — interfaces removed |
| A09-1 | LOW | `LibExtrospectMetamorphic`: `Metamorphic` error declared in library but absent from external interface `IExtrospectMetamorphicV1` -- ABI consumers cannot decode revert data without importing library | FIXED — interfaces removed |
