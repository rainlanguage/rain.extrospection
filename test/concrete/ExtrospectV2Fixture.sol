// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IExtrospectV2} from "src/interface/IExtrospectV2.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {LibExtrospectERC1167Proxy} from "src/lib/LibExtrospectERC1167Proxy.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {LibExtrospectMetamorphic} from "src/lib/LibExtrospectMetamorphic.sol";

/// @dev Test-only concrete binding `IExtrospectV2` to the libraries: every
/// function forwards to the library function it names, the shape the
/// deployable concrete in rain.extrospection.deploy takes. Exists so this
/// repo's tests exercise the declared interface surface against the
/// libraries; it is not the deployable concrete and pins no deploy
/// address.
contract ExtrospectV2Fixture is IExtrospectV2 {
    /// @inheritdoc IExtrospectV2
    function checkCBORTrimmedBytecodeHash(address account, bytes32 expectedTrimmedHash) external view {
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(account, expectedTrimmedHash);
    }

    /// @inheritdoc IExtrospectV2
    function checkNoSolidityCBORMetadata(address account) external view {
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(account);
    }

    /// @inheritdoc IExtrospectV2
    function checkNotEOFBytecode(bytes memory bytecode) external pure {
        LibExtrospectBytecode.checkNotEOFBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV2
    function checkNotMetamorphic(bytes memory bytecode) external pure {
        LibExtrospectMetamorphic.checkNotMetamorphic(bytecode);
    }

    /// @inheritdoc IExtrospectV2
    function checkNotMetamorphic(address account) external view {
        LibExtrospectMetamorphic.checkNotMetamorphic(account.code);
    }

    /// @inheritdoc IExtrospectV2
    function isBeaconImplementationBytecode(address beacon, bytes32 expectedRuntimeHash) external view returns (bool) {
        return LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(beacon, expectedRuntimeHash);
    }

    /// @inheritdoc IExtrospectV2
    function isBeaconOwner(address beacon, address expectedOwner) external view returns (bool) {
        return LibExtrospectERC1967BeaconProxy.isBeaconOwner(beacon, expectedOwner);
    }

    /// @inheritdoc IExtrospectV2
    function isEOFBytecode(bytes memory bytecode) external pure returns (bool) {
        return LibExtrospectBytecode.isEOFBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV2
    function isERC1167Proxy(bytes memory bytecode) external pure returns (bool, address) {
        // False positive: tuple pass-through — both components re-emitted as
        // this function's own return, nothing discarded.
        // slither-disable-next-line unused-return
        return LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
    }

    /// @inheritdoc IExtrospectV2
    function scanEVMOpcodesPresentInBytecode(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV2
    function scanEVMOpcodesPresentInBytecode(address account) external view returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(account.code);
    }

    /// @inheritdoc IExtrospectV2
    function scanEVMOpcodesReachableInBytecode(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode);
    }

    /// @inheritdoc IExtrospectV2
    function scanEVMOpcodesReachableInBytecode(address account) external view returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(account.code);
    }

    /// @inheritdoc IExtrospectV2
    function scanMetamorphicRisk(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectMetamorphic.scanMetamorphicRisk(bytecode);
    }

    /// @inheritdoc IExtrospectV2
    function scanMetamorphicRisk(address account) external view returns (uint256) {
        return LibExtrospectMetamorphic.scanMetamorphicRisk(account.code);
    }

    /// @inheritdoc IExtrospectV2
    function tryTrimSolidityCBORMetadata(bytes memory bytecode) external pure returns (bool, bytes memory) {
        bool didTrim = LibExtrospectBytecode.tryTrimSolidityCBORMetadata(bytecode);
        return (didTrim, bytecode);
    }
}
