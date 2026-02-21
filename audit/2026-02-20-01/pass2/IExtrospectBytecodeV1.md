# Pass 2: Test Coverage — A05 — IExtrospectBytecodeV1

## Evidence of Thorough Reading

**Source file:** `src/interface/deprecated/IExtrospectBytecodeV1.sol`

**Interface name:** `IExtrospectBytecodeV1` (line 11)

**Functions declared:**

| Function | Line |
|---|---|
| `bytecode(address account) external view returns (bytes memory)` | 19 |
| `bytecodeHash(address account) external view returns (bytes32)` | 28 |
| `scanEVMOpcodesPresentInAccount(address account) external view returns (uint256 scan)` | 55 |

## Test Coverage Search Results

- `IExtrospectBytecodeV1` across all `.sol` files in `test/` — 0 matches
- `bytecodeHash` across all `.sol` files in `test/` — 0 matches
- `scanEVMOpcodesPresentInAccount` across all `.sol` files in `test/` — 0 matches
- `test/src/interface/` contains only `IExtrospectInterpreterV1.t.sol` and `IExtrospectMetamorphicV1.t.sol`

All three declared functions have zero test coverage through this interface.

## Findings

### A05-1: No test file exists for `IExtrospectBytecodeV1` — **INFO**

There is no dedicated test file for this interface. The directory `test/src/interface/deprecated/` does not exist. While underlying library logic is exercised indirectly via V2-aligned lib tests, no test ever calls these functions through the `IExtrospectBytecodeV1` interface type.

### A05-2: `bytecodeHash` NatSpec documents an incorrect return value for funded EOAs — **LOW**

The V1 NatSpec (lines 26–27) states "Will be `0` (NOT the hash of empty bytes) for non-contract accounts." Per EIP-1052, funded EOAs return `keccak256("")`, not `0`. The V2 interface corrects this. No test was written to document or confirm this distinction for V1.
