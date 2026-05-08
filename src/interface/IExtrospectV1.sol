// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title IExtrospectV1
/// @notice External interface for the concrete `Extrospect` contract.
/// Consumers (cross-repo tests, offchain tooling, contracts that want to
/// call extrospection at the deterministic Zoltu address without
/// re-deploying the bytecode) should depend on this interface rather than
/// importing `Extrospect` directly. The `V1` suffix follows the rain
/// convention — additive changes append to a `V2` interface, the V1
/// surface stays frozen for downstream consumers.
interface IExtrospectV1 {
    /// @notice Whether the bytecode begins with the EOF magic prefix
    /// (`0xEF00...`).
    function isEOFBytecode(bytes memory bytecode) external pure returns (bool);

    /// @notice Reverts with `EOFBytecodeNotSupported` if the bytecode is
    /// EOF.
    function checkNotEOFBytecode(bytes memory bytecode) external pure;

    /// @notice Attempts to trim the standard 53-byte Solidity CBOR
    /// metadata trailer in place. Returns `(didTrim, trimmedBytecode)`.
    /// `didTrim == false` means the trailer didn't match the expected
    /// shape; the bytes are returned unchanged.
    function tryTrimSolidityCBORMetadata(bytes memory bytecode) external pure returns (bool didTrim, bytes memory trimmedBytecode);

    /// @notice Reads the account's runtime code, trims standard Solidity
    /// CBOR metadata, and asserts the trimmed keccak equals `expected`.
    /// Reverts with `MetadataNotTrimmed` if no metadata was found, or
    /// `BytecodeHashMismatch` if the trimmed hash differs.
    function checkCBORTrimmedBytecodeHash(address account, bytes32 expected) external view;

    /// @notice Reads the account's runtime code and reverts with
    /// `UnexpectedMetadata` if standard Solidity CBOR metadata is
    /// detected. Inverse of `checkCBORTrimmedBytecodeHash` — use when
    /// the build was supposed to produce metadata-free bytecode.
    function checkNoSolidityCBORMetadata(address account) external view;

    /// @notice Bitmap of opcodes reachable in the bytecode under a linear
    /// JUMPDEST-respecting scan. Bit N corresponds to opcode 0xN.
    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) external pure returns (uint256);

    /// @notice Bitmap of opcodes present in the bytecode under a linear
    /// PUSH*-aware scan. Includes unreachable opcodes; use
    /// `scanEVMOpcodesReachableInBytecode` for a tighter analysis.
    function scanEVMOpcodesPresentInBytecode(bytes memory bytecode) external pure returns (uint256);

    /// @notice Bitmap of metamorphic-risk opcodes (SELFDESTRUCT,
    /// DELEGATECALL, CALLCODE, CREATE, CREATE2) reachable in the
    /// bytecode.
    function scanMetamorphicRisk(bytes memory bytecode) external pure returns (uint256);

    /// @notice Reverts if the bytecode contains any reachable
    /// metamorphic-risk opcode.
    function checkNotMetamorphic(bytes memory bytecode) external pure;

    /// @notice Whether the bytecode is an ERC-1167 minimal proxy. Returns
    /// `(true, implementation)` if so, `(false, address(0))` otherwise.
    function isERC1167Proxy(bytes memory bytecode) external pure returns (bool, address);

    /// @notice Whether the bytecode at `beacon.implementation()` has a
    /// runtime keccak equal to `expectedRuntimeHash`.
    function isBeaconImplementationBytecode(address beacon, bytes32 expectedRuntimeHash) external view returns (bool);

    /// @notice Whether `beacon.owner()` equals `expectedOwner`.
    function isBeaconOwner(address beacon, address expectedOwner) external view returns (bool);
}
