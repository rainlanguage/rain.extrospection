// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title IExtrospectV1
/// @notice External interface for the concrete `Extrospect` contract.
/// Function order matches the filesystem ordering of the per-function
/// test files under `test/src/concrete/Extrospect.<fn>.t.sol`.
interface IExtrospectV1 {
    /// @notice See `LibExtrospectBytecode.checkCBORTrimmedBytecodeHash`.
    function checkCBORTrimmedBytecodeHash(address account, bytes32 expected) external view;

    /// @notice See `LibExtrospectBytecode.checkNoSolidityCBORMetadata`.
    function checkNoSolidityCBORMetadata(address account) external view;

    /// @notice See `LibExtrospectBytecode.checkNotEOFBytecode`.
    function checkNotEOFBytecode(bytes memory bytecode) external pure;

    /// @notice See `LibExtrospectMetamorphic.checkNotMetamorphic`.
    function checkNotMetamorphic(bytes memory bytecode) external pure;

    /// @notice See `LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode`.
    function isBeaconImplementationBytecode(address beacon, bytes32 expectedRuntimeHash) external view returns (bool);

    /// @notice See `LibExtrospectERC1967BeaconProxy.isBeaconOwner`.
    function isBeaconOwner(address beacon, address expectedOwner) external view returns (bool);

    /// @notice See `LibExtrospectBytecode.isEOFBytecode`.
    function isEOFBytecode(bytes memory bytecode) external pure returns (bool);

    /// @notice See `LibExtrospectERC1167Proxy.isERC1167Proxy`.
    function isERC1167Proxy(bytes memory bytecode) external pure returns (bool, address);

    /// @notice See `LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode`.
    function scanEVMOpcodesPresentInBytecode(bytes memory bytecode) external pure returns (uint256);

    /// @notice See `LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode`.
    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) external pure returns (uint256);

    /// @notice See `LibExtrospectMetamorphic.scanMetamorphicRisk`.
    function scanMetamorphicRisk(bytes memory bytecode) external pure returns (uint256);

    /// @notice See `LibExtrospectBytecode.tryTrimSolidityCBORMetadata`.
    function tryTrimSolidityCBORMetadata(bytes memory bytecode)
        external
        pure
        returns (bool didTrim, bytes memory trimmedBytecode);
}
