// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibExtrospectBytecode} from "../lib/LibExtrospectBytecode.sol";
import {LibExtrospectMetamorphic} from "../lib/LibExtrospectMetamorphic.sol";
import {LibExtrospectERC1167Proxy} from "../lib/LibExtrospectERC1167Proxy.sol";
import {LibExtrospectERC1967BeaconProxy} from "../lib/LibExtrospectERC1967BeaconProxy.sol";

/// @title Extrospect
/// @notice Concrete contract exposing the public surface of every
/// extrospection library as `external` methods. Parameterless constructor
/// for deterministic Zoltu deployment across EVM networks.
///
/// All library functions in this repo are `internal`, which means Solidity
/// inlines them into the calling frame. That's the right choice for
/// inter-library composition but it leaves no external entry point for:
///
/// - Offchain consumers calling extrospection at a deterministic address.
/// - Tests in dependent repos that need to assert library-internal reverts
///   via `vm.expectRevert`. `expectRevert` requires the revert at a depth
///   below the cheatcode call; an inlined library call shares the test
///   contract's frame, so the cheatcode never sees a frame deeper than
///   itself. An external hop fixes this.
contract Extrospect {
    /// @notice See `LibExtrospectBytecode.isEOFBytecode`.
    function isEOFBytecode(bytes memory bytecode) external pure returns (bool) {
        return LibExtrospectBytecode.isEOFBytecode(bytecode);
    }

    /// @notice See `LibExtrospectBytecode.checkNotEOFBytecode`.
    function checkNotEOFBytecode(bytes memory bytecode) external pure {
        LibExtrospectBytecode.checkNotEOFBytecode(bytecode);
    }

    /// @notice See `LibExtrospectBytecode.tryTrimSolidityCBORMetadata`.
    function tryTrimSolidityCBORMetadata(bytes memory bytecode) external pure returns (bool didTrim, bytes memory) {
        didTrim = LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode);
        return (didTrim, bytecode);
    }

    /// @notice See `LibExtrospectBytecode.checkCBORTrimmedBytecodeHash`.
    function checkCBORTrimmedBytecodeHash(address account, bytes32 expected) external view {
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(account, expected);
    }

    /// @notice See `LibExtrospectBytecode.checkNoSolidityCBORMetadata`.
    function checkNoSolidityCBORMetadata(address account) external view {
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(account);
    }

    /// @notice See `LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode`.
    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode);
    }

    /// @notice See `LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode`.
    function scanEVMOpcodesPresentInBytecode(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(bytecode);
    }

    /// @notice See `LibExtrospectMetamorphic.scanMetamorphicRisk`.
    function scanMetamorphicRisk(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectMetamorphic.scanMetamorphicRisk(bytecode);
    }

    /// @notice See `LibExtrospectMetamorphic.checkNotMetamorphic`.
    function checkNotMetamorphic(bytes memory bytecode) external pure {
        LibExtrospectMetamorphic.checkNotMetamorphic(bytecode);
    }

    /// @notice See `LibExtrospectERC1167Proxy.isERC1167Proxy`.
    function isERC1167Proxy(bytes memory bytecode) external pure returns (bool, address) {
        return LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
    }

    /// @notice See `LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode`.
    function isBeaconImplementationBytecode(address beacon, bytes32 expectedRuntimeHash) external view returns (bool) {
        return LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(beacon, expectedRuntimeHash);
    }

    /// @notice See `LibExtrospectERC1967BeaconProxy.isBeaconOwner`.
    function isBeaconOwner(address beacon, address expectedOwner) external view returns (bool) {
        return LibExtrospectERC1967BeaconProxy.isBeaconOwner(beacon, expectedOwner);
    }
}
