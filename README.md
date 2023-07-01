# rain.extrospection

Docs at https://rainprotocol.github.io/rain.extrospection

## Extrospection

Extrospection is a collection of interfaces, libraries and an implementation
contract that expose onchain logic to offchain tooling.

Focus is on analysing the bytecode of contracts directly, such as deciding
whether we can prove that an address is immutable due to the absence of all state
changing opcodes.

Efforts have been made to implement the logic efficiently but it is expected that
the primary execution environment will be offchain, so there are somewhat gas
intensive algorithms in this repository.

### `IExtrospectBytecodeV2`

Tools to read and get a basic understanding of what opcodes are used in the
bytecode of some address.

The most basic functions `bytecode` and `bytecodeHash` simply expose the
underlying native evm logic for each.

The more sophisticated `scanEVMOpcodesPresentInAccount` and
`scanEVMOpcodesReachableInAccount` build a bitmap of all the opcodes that are
present in the scanned contract. This bitmap is built as `1 << opcode` where
opcode is a single byte, and the scan is a `uint256` so the space of all opcodes
as a `uint8` maps perfectly to all the bits in an EVM word.

The "present in" scan simply loops over the entire bytecode, but is `PUSH*` aware
so knows that the inline argument to any `PUSH` opcode is not itself an opcode.
This is the most conservative scan but can easily trigger false positives, such
as due to bytes in the CBOR metadata commonly appended to contracts by solidity.

CBOR metadata MAY be disabled in newer versions of Solidity and is not present
in other EVM language compilers.

The "reachable in" scan understands enough about the EVM execution environment to
ignore data that is not reachable by a `JUMPDEST`. This is achieved by pausing
the scanner after any opcode that halts execution, then resuming it once a jump
destination is found. This scan DOES NOT cause false positives due to metdata or
similar "data only" regions of a contract, however it is susceptible to breakages
if the EVM execution model ever changes. For example, if the set of halting ops
ever changes, or a new `JUMPDEST` alternative is invented, the scanner will
require an entirely new implementation and redeployment to support this.

### `IExtrospectERC1167ProxyV1`

Check if a given account is an `ERC1167` minimal proxy contract.

https://eips.ethereum.org/EIPS/eip-1167

The minimal proxy contract has exact bytecode so we can easily check if any
account is a proxy and extract the implementation address that is being proxied.

Having a canonical onchain check for this simplifies downstream tooling and
minimises the surface area for implementation bugs.

### `IExtrospectInterpreterV1`

Check if a candidate interpreter contract is fundamentally UNSAFE due to
mutation.

One fundamental hard requirement of an interpreter is that it is NOT mutable.
Most obviously this includes `SELFDESTRUCT` as that would allow for things like
metamorphic languages, which would completely undermine the integrity of any
expression that runs on the interpreter.

Less obviously, every opcode that would fail a standard static call is also
disallowed within interpreters. This gives interpreters a guaranteed familiar
set of security guarantees without needing to consider their internal
implementation.

Pragmatically this is a thin wrapper around the bytecode scanning tools that
check for reachability of dangerous opcodes in the underlying.

This interface and/or concrete implementations are subject to change if/when new
opcodes are supported by the EVM due to future hard forks.