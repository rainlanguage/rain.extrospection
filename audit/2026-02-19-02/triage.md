# Triage: Audit 2026-02-19-02

## HIGH

| ID | Pass | File | Summary | Status |
|----|------|------|---------|--------|
| A03-P2-1 | 2 | IExtrospectInterpreterV1 | Security-critical bitmap constants `NON_STATIC_OPS` and `INTERPRETER_DISALLOWED_OPS` have zero test coverage | FIXED |

## MEDIUM

| ID | Pass | File | Summary | Status |
|----|------|------|---------|--------|
| A06-F01 | 2 | LibExtrospectBytecode | No test for empty bytecode on `scanEVMOpcodesPresentInBytecode` | FIXED |
| A06-F02 | 2 | LibExtrospectBytecode | No test for empty bytecode on `scanEVMOpcodesReachableInBytecode` | FIXED |
| A06-F03 | 2 | LibExtrospectBytecode | No test for truncated PUSH data at end of bytecode | FIXED |
| A07-P2-1 | 2 | LibExtrospectERC1167Proxy | Prefix/suffix fuzz tests don't constrain bytecode length to 45 | FIXED |
| A04-P3-1 | 3 | IExtrospectBytecodeV1 | Missing `@param`/`@return` NatSpec on `scanEVMOpcodesPresentInAccount` | DISMISSED |
| A04-P3-3 | 3 | IExtrospectBytecodeV1 | `bytecodeHash` return docs oversimplify EIP-1052 behavior | DISMISSED |

## LOW

| ID | Pass | File | Summary | Status |
|----|------|------|---------|--------|
| A00-1 | 0 | CLAUDE.md | `rainix-sol-prelude` ordering is ambiguous | FIXED |
| A01-1 | 1 | IExtrospectBytecodeV2 | `bytecodeHash` doc inaccuracy for EOAs vs non-existent accounts | FIXED |
| A03-4 | 1 | IExtrospectInterpreterV1 | Missing return value NatSpec polarity documentation | PENDING |
| A04-1 | 1 | IExtrospectBytecodeV1 | `bytecodeHash` doc same issue as A01-1 | PENDING |
| A04-5 | 1 | IExtrospectBytecodeV1 | No precompile address specification | PENDING |
| A05-F01 | 2 | EVMOpcodes | No direct validation of 124 of 135 opcode constant values | PENDING |
| A05-F02 | 2 | EVMOpcodes | No direct test asserting `HALTING_BITMAP` computed value | PENDING |
| A05-F03 | 2 | EVMOpcodes | JUMP in `HALTING_BITMAP` has no dedicated halting test | PENDING |
| A06-F04 | 2 | LibExtrospectBytecode | No single-byte bytecode tests for scanning functions | PENDING |
| A06-F05 | 2 | LibExtrospectBytecode | No test for exactly 53-byte bytecode in `tryTrimSolidityCBORMetadata` | PENDING |
| A06-F06 | 2 | LibExtrospectBytecode | No idempotency test for `tryTrimSolidityCBORMetadata` | PENDING |
| A06-F08 | 2 | LibExtrospectBytecode | No test for `checkCBORTrimmedBytecodeHash` with empty account | PENDING |
| A07-P2-2 | 2 | LibExtrospectERC1167Proxy | No test validates constant values against ERC-1167 spec | FIXED |
| A07-P2-3 | 2 | LibExtrospectERC1167Proxy | No test for 45-byte bytecode with both prefix and suffix wrong | FIXED |
| A01-P3-1 | 3 | IExtrospectBytecodeV2 | `bytecodeHash` doc inaccurately describes non-contract accounts | PENDING |
| A03-P3-1 | 3 | IExtrospectInterpreterV1 | Missing `@param` tag for `interpreter` parameter | PENDING |
| A03-P3-2 | 3 | IExtrospectInterpreterV1 | Missing `@return` tag -- boolean polarity undocumented | PENDING |
| A04-P3-2 | 3 | IExtrospectBytecodeV1 | Typo "prescence" should be "presence" | PENDING |
| A04-P3-4 | 3 | IExtrospectBytecodeV1 | Functions use implicit `@notice` instead of explicit tags | PENDING |
| A05-P3-1 | 3 | EVMOpcodes | No file-level documentation | PENDING |
| A05-P3-2 | 3 | EVMOpcodes | `HALTING_BITMAP` lacks NatSpec documentation | PENDING |
| A06-P3-1 | 3 | LibExtrospectBytecode | `scanEVMOpcodesPresentInBytecode` NatSpec references stale concepts | PENDING |
| A06-P3-5 | 3 | LibExtrospectBytecode | Minor CBOR byte semantics simplification in docs | PENDING |
| A07-P3-1 | 3 | LibExtrospectERC1167Proxy | Library lacks `@notice`/`@dev` description | PENDING |
| A01-P4-6 | 4 | IExtrospectBytecodeV2 | V1 missing NatSpec tags corrected in V2 | PENDING |
| A02-P4-6 | 4 | IExtrospectERC1167ProxyV1 | Minor EIP reference placement inconsistency | PENDING |
| A03-P4-1 | 4 | IExtrospectInterpreterV1 | File-scope bitmap constants in interface violate separation of concerns | PENDING |
| A03-P4-6 | 4 | IExtrospectInterpreterV1 | No tests or consumers within repository | PENDING |
| A04-P4-1 | 4 | IExtrospectBytecodeV1 | Code duplication between V1 and V2 | PENDING |
| A04-P4-3 | 4 | IExtrospectBytecodeV1 | Stale V1 reference in LibExtrospectBytecode NatSpec | PENDING |
| A05-P4-6 | 4 | EVMOpcodes | `pragma ^0.8.18` broader than configured compiler | PENDING |
| A06-P4-1 | 4 | LibExtrospectBytecode | Code duplication between two scan functions | PENDING |
| A06-P4-10 | 4 | LibExtrospectBytecode | Stale NatSpec referencing `extcodecopy` | PENDING |
