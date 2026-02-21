# Pass 3: Documentation — A05 — IExtrospectBytecodeV1

## Evidence of Thorough Reading

**Interface:** `IExtrospectBytecodeV1` (line 11)

**Functions:**

| Function | Line | @param | @return |
|---|---|---|---|
| `bytecode(address account)` | 19 | Yes | Yes |
| `bytecodeHash(address account)` | 28 | Yes | Yes (inaccurate) |
| `scanEVMOpcodesPresentInAccount(address account)` | 55 | NO | NO |

## Findings

### A05-1: `bytecodeHash` return NatSpec inaccurately describes behavior for funded EOAs — **LOW**

Lines 26-27 conflate non-existent accounts (return `0`) with funded EOAs (return `keccak256("")`). V2 corrects this.

### A05-2: `scanEVMOpcodesPresentInAccount` has no `@param` or `@return` NatSpec tags — **MEDIUM**

24 lines of description but no formal `@param account` or `@return scan` tags. V2 adds both.

### A05-3: No deprecation notice in NatSpec — **INFO**

File is in `deprecated/` but no NatSpec indicates deprecation or points to V2.

### A05-4: `scanEVMOpcodesPresentInAccount` does not document EOF revert behavior — **INFO**

The underlying library reverts with `EOFBytecodeNotSupported` on EOF bytecode. Undocumented in the interface.
