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

### Scanned CBOR metadata

Note that the CBOR metadata appended by default to contracts compiled by Solidity
is IN SCOPE of the opcode scanning. This is because a simple opcode scanner has
no way to verify which bytes are reachable jump destinations.

As of Solidity `0.8.18` it is possible to remove the CBOR metadata entirely via.
a compiler flag. Removing the CBOR metadata DOES NOT prevent contracts from being
verified on popular block explorers, although it DOES remove the ipfs hash of
source code being directly included in the contract bytecode.