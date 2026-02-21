# Pass 3: Documentation — A04 — IExtrospectMetamorphicV1

## Evidence of Thorough Reading

**Interface:** `IExtrospectMetamorphicV1` (line 11)

**Functions:**

| Function | Line |
|----------|------|
| `scanMetamorphicRisk(address account)` | 16 |

NatSpec coverage: `@title` and `@notice` present at interface level. Function has untagged description, `@param account`, `@return riskyOpcodes`.

## Findings

### A04-1: Missing `@notice` tag on `scanMetamorphicRisk` — **LOW**

Line 12 has an untagged description. Without explicit `@notice`, `solc --userdoc` and `forge doc` may not pick up the description.

### A04-2: Return value description inaccurate for empty-code accounts — **LOW**

`@return` states "Zero if no metamorphic risk opcodes are reachable." For EOAs/non-existent addresses this is technically true but misleading — code could later be deployed via CREATE2, turning it into a metamorphic risk after the scan.

### A04-3: No documentation of revert on EOF bytecode — **LOW**

The implementation reverts with `EOFBytecodeNotSupported()` for EOF-formatted bytecode. Not documented in the interface NatSpec.

### A04-4: `@notice` frames function as offchain-only despite being callable onchain — **INFO**

The function is `external view` and fully callable onchain, but `@notice` says "offchain processing."

### A04-5: Covered opcode set not enumerated in the interface — **INFO**

References `METAMORPHIC_OPS` in `EVMOpcodes.sol` but does not import it or enumerate the five opcodes.
