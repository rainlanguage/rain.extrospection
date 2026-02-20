# Pass 4: Code Quality — A04 — IExtrospectMetamorphicV1

## Evidence of Thorough Reading

**File:** `src/interface/IExtrospectMetamorphicV1.sol` (17 lines)

**Interface:** `IExtrospectMetamorphicV1` (line 11)

**Functions:**

| Name | Line |
|---|---|
| `scanMetamorphicRisk(address account)` | 16 |

No imports, no file-scope constants, no events, no errors, no structs.

## Findings

### A04-1: Return value semantics ambiguous for zero-code accounts — **LOW**

For an EOA or not-yet-deployed address, bytecode is empty and the scan returns zero — indistinguishable from a scanned contract with no risky opcodes. The caller cannot determine from the return value alone whether scanning found no opcodes or found no bytecode. `IExtrospectERC1167ProxyV1.isERC1167Proxy` handles the analogous ambiguity with a boolean `result`.

### A04-2: Internal `METAMORPHIC_OPS` cross-file reference is opaque in interface context — **INFO**

Line 10 references the `METAMORPHIC_OPS` bitmap in `EVMOpcodes.sol` by name without importing it or enumerating the five opcodes. A caller reading only this interface cannot determine which opcodes constitute metamorphic risk without consulting `EVMOpcodes.sol`.

### A04-3: No concrete implementation in `src/` implements this interface — **INFO**

No contract in `src/` imports or declares itself as implementing `IExtrospectMetamorphicV1`. The library `LibExtrospectMetamorphic.sol` provides the underlying logic but no concrete facade exists. This matches the pattern observed for `IExtrospectInterpreterV1`.
