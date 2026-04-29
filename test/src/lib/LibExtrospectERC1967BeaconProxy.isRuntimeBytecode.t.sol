// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";

/// @title LibExtrospectERC1967BeaconProxyIsRuntimeBytecodeTest
/// @notice Tests `LibExtrospectERC1967BeaconProxy.isRuntimeBytecode`.
contract LibExtrospectERC1967BeaconProxyIsRuntimeBytecodeTest is Test {
    /// Returns true when the target's runtime hashes to the expected
    /// value.
    function testMatches() external {
        EmptyContract target = new EmptyContract();
        assertTrue(LibExtrospectERC1967BeaconProxy.isRuntimeBytecode(address(target), keccak256(address(target).code)));
    }

    /// Returns false when the expected hash differs from the target's
    /// runtime hash.
    function testMismatches(bytes32 wrongHash) external {
        EmptyContract target = new EmptyContract();
        vm.assume(wrongHash != keccak256(address(target).code));
        assertFalse(LibExtrospectERC1967BeaconProxy.isRuntimeBytecode(address(target), wrongHash));
    }
}
