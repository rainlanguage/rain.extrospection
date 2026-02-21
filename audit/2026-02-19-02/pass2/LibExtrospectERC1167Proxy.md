# A07: Test Coverage Audit -- `src/lib/LibExtrospectERC1167Proxy.sol`

## Source File Summary

`LibExtrospectERC1167Proxy.sol` (94 lines) defines a library with 1 function and 10 constants for ERC-1167 minimal proxy detection.

**Constants (lines 7-33):**
- `ERC1167_PREFIX` (10 bytes), `ERC1167_SUFFIX` (15 bytes)
- `ERC1167_PREFIX_HASH`, `ERC1167_SUFFIX_HASH` (derived)
- `ERC1167_PREFIX_START` (0x20), `ERC1167_SUFFIX_START` (62)
- `ERC1167_PREFIX_LENGTH` (10), `ERC1167_SUFFIX_LENGTH` (15)
- `ERC1167_PROXY_LENGTH` (45), `ERC1167_IMPLEMENTATION_ADDRESS_OFFSET` (30)

**Function:** `isERC1167Proxy(bytes memory bytecode)` (line 43) -- returns `(bool result, address implementationAddress)`

## Evidence of Thorough Reading

**Test file `LibExtrospectERC1167Proxy.isERC1167Proxy.t.sol` (105 lines):**
- Contract: `LibExtrospectERC1167ProxyTest`
- `testIsERC1167ProxyLength` (line 18) -- fuzz: wrong-length bytecode
- `testIsERC1167ProxyPrefixFail` (line 26) -- fuzz: bad prefix
- `testIsERC1167ProxySuffixFail` (line 35) -- fuzz: bad suffix
- `testIsERC1167ProxySuccess` (line 45) -- fuzz: valid proxy
- `testIsERC1167ProxySlowFail` (line 53) -- fuzz: slow ref failure
- `testIsERC1167ProxySlowSuccess` (line 62) -- fuzz: slow ref success
- `testIsERC1167ProxyGasFailLength` (line 72) -- gas benchmark: empty
- `testIsERC1167ProxyGasFailPrefix` (line 79) -- gas benchmark: zero 45 bytes
- `testIsERC1167ProxyGasFailSuffix` (line 89) -- gas benchmark: correct prefix, zero suffix
- `testIsERC1167ProxyGasSuccess` (line 98) -- gas benchmark: valid proxy

**Slow reference `LibExtrospectionSlow.sol` (lines 59-95):**
- `isERC1167ProxySlow(bytes memory bytecode)` -- independently slices prefix/suffix by byte-copying

## Findings

### A07-P2-1 [MEDIUM] Prefix/suffix fuzz tests do not constrain total bytecode length to 45

`testIsERC1167ProxyPrefixFail` (line 26) constructs bytecode as `abi.encodePacked(badPrefix, implementation, ERC1167_SUFFIX)`. The fuzz input `badPrefix` is arbitrary `bytes memory`. Since `ERC1167_PREFIX` is 10 bytes, any `badPrefix` that is not exactly 10 bytes produces total length != 45, hitting the length-check early return (line 50) rather than the prefix-hash comparison (line 64).

The `vm.assume` only ensures `keccak256(badPrefix) != keccak256(ERC1167_PREFIX)`, not that `badPrefix.length == 10`. Same issue applies to `testIsERC1167ProxySuffixFail` with `badSuffix`.

The concrete gas tests do exercise 45-byte paths (single case each), and the slow-reference fuzz provides general coverage. But the hash-comparison failure path is not systematically fuzz-tested with correctly-sized bytecode.

**Recommendation:** Add `vm.assume(badPrefix.length == 10)` / `vm.assume(badSuffix.length == 15)`, or create separate fuzz tests with fixed-size inputs.

### A07-P2-2 [LOW] No test validates constant values against the ERC-1167 specification

The 10 constants encode the ERC-1167 bytecode layout but no test independently validates them against hardcoded literals. Tests use these constants to construct test data, creating a circular dependency: if a constant were wrong, tests would construct wrong data and potentially still pass.

**Recommendation:** Add assertions like `assertEq(ERC1167_PREFIX, hex"363d3d373d3d3d363d73")`.

### A07-P2-3 [LOW] No test for 45-byte bytecode with both prefix and suffix wrong

No fuzz test specifically generates 45-byte bytecode where both prefix and suffix are wrong. The concrete gas test with 45 zero bytes covers one case, but systematic coverage of the "both checks fail" path is missing.

### A07-P2-4 [INFO] Slow reference implementation shares constants with the fast implementation

`LibExtrospectionSlow.isERC1167ProxySlow` imports `ERC1167_PREFIX_HASH` and `ERC1167_SUFFIX_HASH` from the source file. While the slow implementation independently slices bytecode, it validates against the same hashes. Mitigated if A07-P2-2 is addressed.

### A07-P2-5 [INFO] Gas benchmark tests discard return values without assertions

The four gas benchmark tests call `isERC1167Proxy` but do not assert on return values. They serve as gas benchmarks only. Correctness is covered by the fuzz and slow-reference tests.
