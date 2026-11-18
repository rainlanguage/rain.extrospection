// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title IExtrospectV1
/// @notice Deprecated by `IExtrospectV2`, which carries this whole surface.
/// Each function forwards to the library function of the same name, whose
/// NatSpec is the behaviour, revert and hazard reference.
/// @dev The custom errors are declared by the libraries. `Metamorphic` is
/// `LibExtrospectMetamorphic`'s; every other is `LibExtrospectBytecode`'s.
interface IExtrospectV1 {
    /// @dev `LibExtrospectBytecode.checkCBORTrimmedBytecodeHash`.
    function checkCBORTrimmedBytecodeHash(address account, bytes32 expectedTrimmedHash) external view;

    /// @dev `LibExtrospectBytecode.checkNoSolidityCBORMetadata`.
    function checkNoSolidityCBORMetadata(address account) external view;

    /// @dev `LibExtrospectBytecode.checkNotEOFBytecode`.
    function checkNotEOFBytecode(bytes memory bytecode) external pure;

    /// @dev `LibExtrospectMetamorphic.checkNotMetamorphic(bytes)`.
    function checkNotMetamorphic(bytes memory bytecode) external pure;

    /// @dev `LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode`.
    function isBeaconImplementationBytecode(address beacon, bytes32 expectedRuntimeHash) external view returns (bool);

    /// @dev `LibExtrospectERC1967BeaconProxy.isBeaconOwner`.
    function isBeaconOwner(address beacon, address expectedOwner) external view returns (bool);

    /// @dev `LibExtrospectBytecode.isEOFBytecode`.
    function isEOFBytecode(bytes memory bytecode) external pure returns (bool);

    /// @dev `LibExtrospectERC1167Proxy.isERC1167Proxy`.
    function isERC1167Proxy(bytes memory bytecode) external pure returns (bool, address);

    /// @dev `LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(bytes)`.
    function scanEVMOpcodesPresentInBytecode(bytes memory bytecode) external pure returns (uint256);

    /// @dev `LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytes)`.
    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) external pure returns (uint256);

    /// @dev `LibExtrospectMetamorphic.scanMetamorphicRisk(bytes)`.
    function scanMetamorphicRisk(bytes memory bytecode) external pure returns (uint256);

    /// @dev `LibExtrospectBytecode.tryTrimSolidityCBORMetadata`, applied to the
    /// calldata-decoded copy of `bytecode`: the caller's bytes are untouched.
    /// @return didTrim True when the metadata was trimmed.
    /// @return trimmedBytecode The trimmed copy, or `bytecode` unchanged when
    /// `didTrim` is false.
    function tryTrimSolidityCBORMetadata(bytes memory bytecode)
        external
        pure
        returns (bool didTrim, bytes memory trimmedBytecode);
}
