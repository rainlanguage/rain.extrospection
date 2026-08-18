// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";
import {CallerKeyedBeacon} from "test/concrete/CallerKeyedBeacon.sol";

contract ExtrospectIsBeaconOwnerTest is ExtrospectEquivalence {
    function testIsBeaconOwnerEquivalenceMatch(address owner) external {
        EmptyContract impl = new EmptyContract();
        MockBeacon beacon = new MockBeacon(address(impl), owner);

        assertEq(
            extrospect.isBeaconOwner(address(beacon), owner),
            LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), owner)
        );
    }

    function testIsBeaconOwnerEquivalenceMismatch(address actual, address wrong) external {
        vm.assume(actual != wrong);
        EmptyContract impl = new EmptyContract();
        MockBeacon beacon = new MockBeacon(address(impl), actual);

        assertEq(
            extrospect.isBeaconOwner(address(beacon), wrong),
            LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), wrong)
        );
    }

    /// The concrete instance queries the beacon as itself; the library
    /// queries it as whichever contract invoked the library. Against a
    /// beacon that keys `owner()` off its caller and singles out the
    /// `Extrospect` instance, the two return opposite answers for the
    /// same beacon and the same expected owner.
    function testIsBeaconOwnerDivergesOnCallerKeyedBeacon() external {
        address defaultOwner = address(uint160(0xA11CE));
        address singledOutOwner = address(uint160(0xBAD));
        CallerKeyedBeacon beacon = new CallerKeyedBeacon(address(extrospect), defaultOwner, singledOutOwner);

        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), defaultOwner));
        assertFalse(extrospect.isBeaconOwner(address(beacon), defaultOwner));
    }
}
