// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title IExtrospectV1
/// @notice External interface to the extrospection libraries. Every
/// function forwards to the library function it names. The concrete
/// implementation (`Extrospect`) and its deployment live in
/// rain.extrospection.deploy.
/// @dev The custom errors named below are declared by the libraries, not by
/// this interface. `EOFBytecodeNotSupported`, `MetadataNotTrimmed`,
/// `BytecodeHashMismatch`, `UnexpectedMetadata` and `CodelessAccount` come
/// from `LibExtrospectBytecode`; `Metamorphic` comes from
/// `LibExtrospectMetamorphic`.
interface IExtrospectV1 {
    /// @notice Reads `account`'s runtime bytecode, trims trailing Solidity CBOR
    /// metadata from it, and reverts unless what remains hashes to
    /// `expectedTrimmedHash`. Reverts `MetadataNotTrimmed` when the bytecode
    /// does not end in the exact metadata structure the trimmer recognises,
    /// so nothing was trimmed. Reverts
    /// `BytecodeHashMismatch(expectedTrimmedHash, actual)` when the trimmed
    /// bytecode hashes to something other than `expectedTrimmedHash`. Reverts
    /// `EOFBytecodeNotSupported` when `account`'s bytecode is EOF. Returns
    /// nothing when the hash matches.
    /// @dev See `LibExtrospectBytecode.checkCBORTrimmedBytecodeHash`.
    /// @param account The account whose runtime bytecode is read and checked.
    /// @param expectedTrimmedHash `keccak256` of the bytecode AFTER its last
    /// 53 bytes are removed, not of the full runtime bytecode. Not the same
    /// value as `isBeaconImplementationBytecode`'s `expectedRuntimeHash`,
    /// which hashes runtime bytecode whole.
    function checkCBORTrimmedBytecodeHash(address account, bytes32 expectedTrimmedHash) external view;

    /// @notice Reads `account`'s runtime bytecode and reverts
    /// `UnexpectedMetadata` when its last 53 bytes are the exact Solidity CBOR
    /// metadata structure `tryTrimSolidityCBORMetadata` recognises. Reverts
    /// `CodelessAccount(account)` when `account` has no code: absence of code
    /// is not absence of metadata risk, so the check refuses to vouch for a
    /// codeless account. Reverts `EOFBytecodeNotSupported` when `account`'s
    /// bytecode is EOF. Returns nothing when the account has code in which no
    /// such metadata is detected, including metadata in any other shape.
    /// @dev See `LibExtrospectBytecode.checkNoSolidityCBORMetadata`.
    /// @param account The account whose runtime bytecode is read and checked.
    function checkNoSolidityCBORMetadata(address account) external view;

    /// @notice Reverts `EOFBytecodeNotSupported` when `bytecode` begins with
    /// the EOF magic `0xEF00`. Returns nothing otherwise.
    /// @dev See `LibExtrospectBytecode.checkNotEOFBytecode`.
    /// @param bytecode The bytecode to check.
    function checkNotEOFBytecode(bytes memory bytecode) external pure;

    /// @notice Reverts `Metamorphic(riskyOpcodes)` when `scanMetamorphicRisk`
    /// reports a non-zero bitmap for `bytecode`, carrying that bitmap: any
    /// reachable metamorphic risk opcode, or a first byte of the EIP-3541
    /// reserved `0xEF` (an EOF container, an EIP-7702 delegation designator,
    /// or any future assignment of the prefix), which reverts
    /// `Metamorphic(1 << 0xEF)`. Never reverts `EOFBytecodeNotSupported`.
    /// Returns nothing when that bitmap is zero.
    /// @dev See `LibExtrospectMetamorphic.checkNotMetamorphic`.
    /// @param bytecode The bytecode to check.
    function checkNotMetamorphic(bytes memory bytecode) external pure;

    /// @notice Static-calls `implementation()` on `beacon` and hashes the
    /// runtime bytecode of the address it returns.
    /// @dev See `LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode`.
    /// @param beacon The address to static-call `implementation()` on.
    /// @param expectedRuntimeHash `keccak256` of the implementation's runtime
    /// bytecode exactly as deployed, with no metadata trimming. Not the same
    /// value as `checkCBORTrimmedBytecodeHash`'s `expectedTrimmedHash`, which
    /// hashes runtime bytecode with its metadata trailer removed. For an
    /// implementation with no code this is `keccak256` of empty bytes.
    /// @return True when the static call succeeds, returns exactly 32 bytes
    /// whose top 12 bytes are zero, and the address in those bytes has runtime
    /// bytecode hashing to `expectedRuntimeHash`. False when the static call
    /// reverts, returns other than 32 bytes, or returns 32 bytes with any of
    /// the top 12 non-zero.
    function isBeaconImplementationBytecode(address beacon, bytes32 expectedRuntimeHash) external view returns (bool);

    /// @notice Static-calls `owner()` on `beacon` and compares the address it
    /// returns against `expectedOwner`.
    /// @dev See `LibExtrospectERC1967BeaconProxy.isBeaconOwner`.
    /// @param beacon The address to static-call `owner()` on.
    /// @param expectedOwner The address the call must return.
    /// @return True when the static call succeeds, returns exactly 32 bytes
    /// whose top 12 bytes are zero, and the address in those bytes equals
    /// `expectedOwner`. False when the static call reverts, returns other than
    /// 32 bytes, or returns 32 bytes with any of the top 12 non-zero.
    function isBeaconOwner(address beacon, address expectedOwner) external view returns (bool);

    /// @notice Whether `bytecode` begins with the EOF magic `0xEF00`. Never
    /// reverts. Bytecode shorter than 2 bytes is not EOF.
    /// @dev See `LibExtrospectBytecode.isEOFBytecode`.
    /// @param bytecode The bytecode to check.
    /// @return True when the first two bytes of `bytecode` are `0xEF00`.
    function isEOFBytecode(bytes memory bytecode) external pure returns (bool);

    /// @notice Whether `bytecode` is the 45 byte ERC-1167 minimal proxy, and
    /// the implementation address embedded in it when it is. Never reverts,
    /// and performs no EOF check.
    /// @dev See `LibExtrospectERC1167Proxy.isERC1167Proxy`.
    /// @param bytecode The bytecode to check.
    /// @return True when `bytecode` is exactly 45 bytes and carries the
    /// ERC-1167 prefix and suffix.
    /// @return The 20 bytes at offset 10 of `bytecode` read as an address, or
    /// the zero address when the first return is false.
    function isERC1167Proxy(bytes memory bytecode) external pure returns (bool, address);

    /// @notice Bitmap of every opcode byte a linear scan of `bytecode` reads,
    /// skipping the inline data of `PUSH*` opcodes. Regions that never execute,
    /// such as trailing metadata, still set bits. Reverts
    /// `EOFBytecodeNotSupported` when `bytecode` is EOF.
    /// @dev See `LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode`.
    /// @param bytecode The bytecode to scan.
    /// @return A bitmap, not a count: bit `N` is set when opcode `N` was read.
    function scanEVMOpcodesPresentInBytecode(bytes memory bytecode) external pure returns (uint256);

    /// @notice Bitmap of the opcodes a linear scan of `bytecode` treats as
    /// reachable. The scan skips the inline data of `PUSH*` opcodes, pauses at
    /// each halting opcode (`STOP`, `JUMP`, `RETURN`, `REVERT`, `INVALID`,
    /// `SELFDESTRUCT`) and resumes at the next `JUMPDEST`, so bytes between a
    /// halt and the next `JUMPDEST` set no bits. Reachability is
    /// over-approximated: a `JUMPDEST` that no execution path can reach still
    /// resumes the scan. Reverts `EOFBytecodeNotSupported` when `bytecode` is
    /// EOF.
    /// @dev See `LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode`.
    /// @param bytecode The bytecode to scan.
    /// @return A bitmap, not a count: bit `N` is set when opcode `N` was
    /// scanned as reachable.
    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) external pure returns (uint256);

    /// @notice Bitmap of the metamorphic risk opcodes
    /// (`SELFDESTRUCT`, `DELEGATECALL`, `CALLCODE`, `CREATE`, `CREATE2`) that
    /// `scanEVMOpcodesReachableInBytecode` finds reachable in `bytecode`.
    /// Bytecode whose first byte is the EIP-3541 reserved `0xEF` — an EOF
    /// container, an EIP-7702 delegation designator, or any future
    /// assignment of the prefix — fails closed to a bitmap of exactly
    /// `1 << 0xEF` instead of being scanned. Never reverts.
    /// @dev See `LibExtrospectMetamorphic.scanMetamorphicRisk`.
    /// @param bytecode The bytecode to scan.
    /// @return A bitmap, not a count or a score: bit `N` is set when
    /// metamorphic opcode `N` is reachable, and bit `0xEF` alone is set when
    /// the first byte is the reserved `0xEF`. Zero when neither holds.
    function scanMetamorphicRisk(bytes memory bytecode) external pure returns (uint256);

    /// @notice Removes the last 53 bytes of `bytecode` when they are the exact
    /// Solidity CBOR metadata structure the trimmer recognises. Metadata in any
    /// other shape is not trimmed and does not revert. Reverts
    /// `EOFBytecodeNotSupported` when `bytecode` is EOF.
    /// @dev See `LibExtrospectBytecode.tryTrimSolidityCBORMetadata`, which
    /// takes `bytes memory` and trims it in place. Across this external
    /// interface the argument arrives as a fresh copy decoded from calldata
    /// into the callee's memory, so the caller's own `bytecode` is untouched:
    /// the trim lands on that copy and the copy comes back as
    /// `trimmedBytecode`.
    /// @param bytecode The bytecode to trim.
    /// @return didTrim True when the last 53 bytes matched and were removed.
    /// @return trimmedBytecode `bytecode` less its last 53 bytes when `didTrim`
    /// is true, otherwise `bytecode` unchanged.
    function tryTrimSolidityCBORMetadata(bytes memory bytecode)
        external
        pure
        returns (bool didTrim, bytes memory trimmedBytecode);
}
