// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IExtrospectV1} from "../interface/IExtrospectV1.sol";
import {LibExtrospectBytecode} from "../lib/LibExtrospectBytecode.sol";
import {LibExtrospectMetamorphic} from "../lib/LibExtrospectMetamorphic.sol";
import {LibExtrospectERC1167Proxy} from "../lib/LibExtrospectERC1167Proxy.sol";
import {LibExtrospectERC1967BeaconProxy} from "../lib/LibExtrospectERC1967BeaconProxy.sol";

/// @title Extrospect
/// @notice Concrete implementation of `IExtrospectV1`. Parameterless
/// constructor for deterministic Zoltu deployment across EVM networks.
/// Consumers should depend on `IExtrospectV1` rather than importing this
/// contract directly.
contract Extrospect is IExtrospectV1 {
    /// @inheritdoc IExtrospectV1
    function checkCBORTrimmedBytecodeHash(address account, bytes32 expected) external view {
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(account, expected);
    }

    /// @inheritdoc IExtrospectV1
    function checkNoSolidityCBORMetadata(address account) external view {
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(account);
    }

    /// @inheritdoc IExtrospectV1
    function checkNotEOFBytecode(bytes memory bytecode) external pure {
        LibExtrospectBytecode.checkNotEOFBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function checkNotMetamorphic(bytes memory bytecode) external pure {
        LibExtrospectMetamorphic.checkNotMetamorphic(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function isBeaconImplementationBytecode(address beacon, bytes32 expectedRuntimeHash) external view returns (bool) {
        return LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(beacon, expectedRuntimeHash);
    }

    /// @inheritdoc IExtrospectV1
    function isBeaconOwner(address beacon, address expectedOwner) external view returns (bool) {
        return LibExtrospectERC1967BeaconProxy.isBeaconOwner(beacon, expectedOwner);
    }

    /// @inheritdoc IExtrospectV1
    function isEOFBytecode(bytes memory bytecode) external pure returns (bool) {
        return LibExtrospectBytecode.isEOFBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function isERC1167Proxy(bytes memory bytecode) external pure returns (bool, address) {
        return LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function scanEVMOpcodesPresentInBytecode(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function scanMetamorphicRisk(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectMetamorphic.scanMetamorphicRisk(bytecode);
    }

    /// @inheritdoc IExtrospectV1
    function tryTrimSolidityCBORMetadata(bytes memory bytecode)
        external
        pure
        returns (bool didTrim, bytes memory trimmedBytecode)
    {
        didTrim = LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode);
        return (didTrim, bytecode);
    }
}
