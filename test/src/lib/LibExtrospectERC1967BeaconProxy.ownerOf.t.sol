// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";

/// @title LibExtrospectERC1967BeaconProxyOwnerOfTest
/// @notice Tests `LibExtrospectERC1967BeaconProxy.ownerOf`.
contract LibExtrospectERC1967BeaconProxyOwnerOfTest is Test {
    /// Returns whatever the beacon's `owner()` getter reports.
    function testReturnsBeaconOwner(address impl, address own) external {
        MockBeacon beacon = new MockBeacon(impl, own);
        assertEq(LibExtrospectERC1967BeaconProxy.ownerOf(address(beacon)), own);
    }

    /// Reverts when the target doesn't expose the `owner()` selector.
    function testRevertsOnNonOwnable() external {
        EmptyContract notOwnable = new EmptyContract();
        vm.expectRevert();
        LibExtrospectERC1967BeaconProxy.ownerOf(address(notOwnable));
    }
}
