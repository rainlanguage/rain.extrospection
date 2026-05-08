// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";

contract ExtrospectIsBeaconOwnerTest is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }

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
}
