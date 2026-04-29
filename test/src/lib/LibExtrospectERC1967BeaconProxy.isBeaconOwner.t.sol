// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";
import {RevertingBeacon} from "test/concrete/RevertingBeacon.sol";

/// @title LibExtrospectERC1967BeaconProxyIsBeaconOwnerTest
/// @notice Tests `LibExtrospectERC1967BeaconProxy.isBeaconOwner`.
contract LibExtrospectERC1967BeaconProxyIsBeaconOwnerTest is Test {
    /// Returns true when the beacon's reported owner matches.
    function testMatches(address impl, address own) external {
        MockBeacon beacon = new MockBeacon(impl, own);
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), own));
    }

    /// Returns false on a mismatch.
    function testMismatches(address impl, address own, address wrong) external {
        vm.assume(wrong != own);
        MockBeacon beacon = new MockBeacon(impl, own);
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), wrong));
    }

    /// A target that doesn't expose `owner()` is not a valid beacon
    /// and trivially fails the predicate. Returns false rather than
    /// reverting so integrators can collapse the check to a single
    /// boolean assertion.
    function testReturnsFalseOnNonOwnable(address expected) external {
        EmptyContract notOwnable = new EmptyContract();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(notOwnable), expected));
    }

    /// A beacon whose `owner()` reverts is also a failure for the
    /// predicate, returning false rather than propagating.
    function testReturnsFalseOnBeaconRevert(address expected) external {
        RevertingBeacon beacon = new RevertingBeacon();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), expected));
    }
}
