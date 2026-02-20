# Pass 2: Test Coverage — A09 — LibExtrospectMetamorphic

## Evidence of Thorough Reading

### Source file (`src/lib/LibExtrospectMetamorphic.sol`)

- **Error** `Metamorphic(uint256 riskyOpcodes)` — line 15
- **Function** `scanMetamorphicRisk(bytes memory bytecode)` — line 21
- **Function** `checkNotMetamorphic(bytes memory bytecode)` — line 27

### Test file 1: `LibExtrospectMetamorphic.scanMetamorphicRisk.t.sol`

10 tests: empty, clean, metamorphic metadata, selfdestruct, delegatecall, callcode, create, create2, fuzz reference, EOF revert.

### Test file 2: `LibExtrospectMetamorphic.checkNotMetamorphic.t.sol`

7 tests: clean, empty, metamorphic metadata revert, selfdestruct revert, delegatecall revert, create2 revert, EOF revert.

### Test helper

`scanMetamorphicRiskSlow` — line 60 of `test/lib/LibExtrospectionSlow.sol`

## Findings

### A09-1: `checkNotMetamorphic` missing individual revert tests for CALLCODE and CREATE — **LOW**

Revert tests exist for SELFDESTRUCT, DELEGATECALL, and CREATE2 but not CALLCODE or CREATE. The concrete contracts `HasCallcode` and `HasCreate` exist but are not used in the `checkNotMetamorphic` test file.

### A09-2: `checkNotMetamorphic` revert tests use bare `vm.expectRevert()` without verifying the `Metamorphic` error type or its `riskyOpcodes` parameter — **LOW**

All four metamorphic-opcode revert tests call `vm.expectRevert()` with no arguments. Any revert would pass the test. The specific `Metamorphic(uint256)` error selector and `riskyOpcodes` bitmap are never asserted.

### A09-3: `checkNotMetamorphic` has no fuzz test — **LOW**

`scanMetamorphicRisk` has a fuzz test against the slow reference. `checkNotMetamorphic` has no equivalent fuzz test verifying "reverts iff scanMetamorphicRisk returns non-zero".
