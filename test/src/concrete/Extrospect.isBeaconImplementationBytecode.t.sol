// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";

contract ExtrospectIsBeaconImplementationBytecodeTest is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }

    function testIsBeaconImplementationBytecodeEquivalenceMatch() external {
        EmptyContract impl = new EmptyContract();
        MockBeacon beacon = new MockBeacon(address(impl), address(this));
        bytes32 expected = keccak256(address(impl).code);

        assertEq(
            extrospect.isBeaconImplementationBytecode(address(beacon), expected),
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), expected)
        );
    }

    function testIsBeaconImplementationBytecodeEquivalenceMismatch(bytes32 wrong) external {
        EmptyContract impl = new EmptyContract();
        MockBeacon beacon = new MockBeacon(address(impl), address(this));
        vm.assume(wrong != keccak256(address(impl).code));

        assertEq(
            extrospect.isBeaconImplementationBytecode(address(beacon), wrong),
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), wrong)
        );
    }
}
