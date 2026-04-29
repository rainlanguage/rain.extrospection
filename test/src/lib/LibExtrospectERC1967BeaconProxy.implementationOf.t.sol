// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";

/// @title LibExtrospectERC1967BeaconProxyImplementationOfTest
/// @notice Tests `LibExtrospectERC1967BeaconProxy.implementationOf`.
contract LibExtrospectERC1967BeaconProxyImplementationOfTest is Test {
    /// Returns whatever the beacon's `implementation()` getter reports.
    function testReturnsBeaconImplementation(address impl, address own) external {
        MockBeacon beacon = new MockBeacon(impl, own);
        assertEq(LibExtrospectERC1967BeaconProxy.implementationOf(address(beacon)), impl);
    }

    /// Reverts when the target doesn't expose the `implementation()`
    /// selector.
    function testRevertsOnNonBeacon() external {
        EmptyContract notABeacon = new EmptyContract();
        vm.expectRevert();
        LibExtrospectERC1967BeaconProxy.implementationOf(address(notABeacon));
    }
}
