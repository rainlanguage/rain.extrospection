# rain.extrospection

Docs at https://rainprotocol.github.io/rain.extrospection

## Extrospection

Extrospection is a collection of interfaces and libraries that expose onchain
logic to offchain tooling.

Focus is on analysing the bytecode of contracts directly, such as deciding
whether we can prove that an address is immutable due to the absence of all
state changing opcodes.

Efforts have been made to implement the logic efficiently but it is expected
that the primary execution environment will be offchain, so there are somewhat
gas intensive algorithms in this repository.

### `IExtrospectV1`

`src/interface/IExtrospectV1.sol` is the external interface. Each of its
functions forwards to the library function of the same name and does nothing
else, so the interface is a call-and-return view of the libraries below. The
concrete implementation (`Extrospect`) and its deterministic deployment live in
the rain.extrospection.deploy repo.

`src/interface/IBeacon.sol` and `src/interface/IOwnable.sol` are the minimal
`implementation()` and `owner()` interfaces used to query beacons.

### Opcode scanning

`LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode` and
`LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode` build a bitmap of the
opcodes found in the bytecode passed to them. This bitmap is built as
`1 << opcode` where opcode is a single byte, and the scan is a `uint256` so the
space of all opcodes as a `uint8` maps perfectly to all the bits in an EVM word.

Both scans take bytecode as `bytes memory` rather than an address, so the caller
chooses what to feed them: `account.code`, a constructor argument, or bytecode
already trimmed by `tryTrimSolidityCBORMetadata`.

The "present in" scan simply loops over the entire bytecode, but is `PUSH*`
aware so knows that the inline argument to any `PUSH` opcode is not itself an
opcode. This is the most conservative scan but can easily trigger false
positives, such as due to bytes in the CBOR metadata commonly appended to
contracts by solidity.

CBOR metadata MAY be disabled in newer versions of Solidity and is not present
in other EVM language compilers.

The "reachable in" scan understands enough about the EVM execution environment
to ignore data that is not reachable by a `JUMPDEST`. This is achieved by
pausing the scanner after any opcode that halts execution, then resuming it once
a jump destination is found. A "data only" region such as the CBOR metadata is
skipped only for as long as the scanner stays paused. A `0x5b` byte that the
linear sweep lands on inside such a region resumes the scan, and every opcode
after it in that region is reported as reachable. The scanner is susceptible to
breakages if the EVM execution model ever changes. For example, if the set of
halting ops ever changes, or a new `JUMPDEST` alternative is invented, the
scanner will require an entirely new implementation and redeployment to support
this.

Both scans revert with `EOFBytecodeNotSupported` on EOF bytecode.

### Bytecode hashing and Solidity CBOR metadata

`LibExtrospectBytecode.tryTrimSolidityCBORMetadata` recognises the default
Solidity CBOR metadata trailer and shortens the bytecode in place past it,
reporting whether it trimmed.

`checkCBORTrimmedBytecodeHash(account, expected)` trims an account's code and
reverts unless the hash of what remains equals `expected`, so the comparison is
against bytecode with the compiler's embedded metadata hash removed. It reverts
with `MetadataNotTrimmed` when there was no metadata trailer to trim at all,
before any hash comparison happens.

`checkNoSolidityCBORMetadata(account)` is the inverse: it reverts when metadata
is detected at all, for bytecode that was compiled with metadata disabled. It
also reverts with `CodelessAccount` when the account has no code at all: no
absence check answers "no code" as a pass, because a codeless account can gain
any code later.

`isEOFBytecode` and `checkNotEOFBytecode` report and enforce that bytecode is
not EOF formatted.

### ERC-1167 minimal proxies

`LibExtrospectERC1167Proxy.isERC1167Proxy` checks whether bytecode is an
`ERC1167` minimal proxy contract and extracts the implementation address it
proxies.

https://eips.ethereum.org/EIPS/eip-1167

The minimal proxy contract has exact bytecode so we can easily check if any
account is a proxy and extract the implementation address that is being proxied.

Having a canonical onchain check for this simplifies downstream tooling and
minimises the surface area for implementation bugs.

The check is exact. Only the canonical 45 byte form matches: the 10 byte prefix,
a `PUSH20` implementation address, and the 15 byte suffix whose jump target is
`0x2b`. The vanity proxies of the EIP, which shorten the bytecode to `45 - Z`
bytes when the implementation address has `Z` leading zero bytes, do not match.
Neither do `PUSH0` based minimal proxies, nor EIP-7702 delegation designators. A
`false` result says that the bytecode is not the canonical minimal proxy, not
that the account runs its own code.

### ERC-1967 beacon proxies

`LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode` calls
`implementation()` on a beacon and compares the runtime bytecode hash of the
answer against an expected hash. `isBeaconOwner` calls `owner()` on a beacon and
compares the answer against an expected owner. Both return `false` rather than
reverting when the call fails for any reason, including the target not being a
beacon at all.

The same file exports `ERC1967_IMPLEMENTATION_SLOT`, `ERC1967_ADMIN_SLOT` and
`ERC1967_BEACON_SLOT`, derived in source from the EIP-1967 formula. ERC-1967
specifies those slots but no getter for them, so reading a proxy's beacon slot
needs storage access that a runtime contract context does not have.

### Metamorphic risk

`LibExtrospectMetamorphic.scanMetamorphicRisk` masks the reachable opcode scan
against `METAMORPHIC_OPS` and returns the risky opcodes that are reachable.
`checkNotMetamorphic` reverts with `Metamorphic(riskyOpcodes)` when that result
is non-zero.

Bytecode whose first byte is `0xEF` fails closed: `scanMetamorphicRisk` reports
a bitmap of exactly `1 << 0xEF` without scanning, and `checkNotMetamorphic`
therefore reverts. EIP-3541 reserves that lead byte for protocol features — an
EOF container (`0xEF00`), an EIP-7702 delegation designator
(`0xEF0100 || address`, which the account holder repoints or revokes with one
transaction), or whatever the prefix is assigned next — that a legacy opcode
scan cannot reason about; pre-London deployments and chains without EIP-3541 can
hold `0xEF`-lead legacy code indistinguishable by inspection. The scan keys on
the first byte alone and refuses to vouch rather than misread the bytes as
opcodes. This makes the metamorphic pair total over bytes: it is the one place
that answers the reserved prefix with a verdict, while the raw opcode scans keep
reverting `EOFBytecodeNotSupported` on the `0xEF00` EOF magic.

Both functions also have address-taking entry points that read the account's
code, revert with `CodelessAccount` when there is none, and delegate to the
bytes functions otherwise. An account with no code is the maximally metamorphic
state — an unoccupied `CREATE2` target, a self-destructed account between
incarnations, or an EOA that can gain code by EIP-7702 delegation — so only the
address boundary has the information to refuse to vouch for it. The bytes entry
points stay total over bytes and answer only about the bytes given.

One fundamental hard requirement of an interpreter is that it is NOT mutable.
Most obviously this includes `SELFDESTRUCT` as that would allow for things like
metamorphic languages, which would completely undermine the integrity of any
expression that runs on the interpreter. `METAMORPHIC_OPS` covers
`SELFDESTRUCT`, `DELEGATECALL`, `CALLCODE`, `CREATE` and `CREATE2`.

### `EVMOpcodes` constants

`src/lib/EVMOpcodes.sol` defines one `EVM_OP_*` constant per opcode defined
through Cancun — 149 of them. The other 107 of the 256 byte values are not
assigned opcodes and so have no constant, while the scan bitmaps still cover all
256 bit positions.

The derived bitmaps are:

- `HALTING_BITMAP` — opcodes that terminate the current execution path, used by
  the reachable scan.
- `METAMORPHIC_OPS` — opcodes that indicate metamorphic risk, used by
  `LibExtrospectMetamorphic`.
- `NON_STATIC_OPS` — opcodes disallowed in a static context per EIP-214.
- `INTERPRETER_DISALLOWED_OPS` — `NON_STATIC_OPS` plus `SLOAD`, `TLOAD`,
  `DELEGATECALL` and `CALLCODE`.

`NON_STATIC_OPS` and `INTERPRETER_DISALLOWED_OPS` are exported constants only.
No library and no `IExtrospectV1` function in this repository reads either of
them. A caller wanting an interpreter safety check masks a reachable scan
against `INTERPRETER_DISALLOWED_OPS` itself.

The opcode constants, and the bitmaps derived from them, are subject to change
if/when new opcodes are supported by the EVM due to future hard forks.
