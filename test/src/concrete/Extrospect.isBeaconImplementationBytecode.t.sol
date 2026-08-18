// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";
import {CallerKeyedBeacon} from "test/concrete/CallerKeyedBeacon.sol";

contract ExtrospectIsBeaconImplementationBytecodeTest is ExtrospectEquivalence {
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

    /// The concrete instance queries the beacon as itself; the library
    /// queries it as whichever contract invoked the library. Against a
    /// beacon that keys `implementation()` off its caller and singles
    /// out the `Extrospect` instance, the two return opposite answers
    /// for the same beacon and the same expected hash.
    function testIsBeaconImplementationBytecodeDivergesOnCallerKeyedBeacon() external {
        EmptyContract impl = new EmptyContract();
        CallerKeyedBeacon beacon = new CallerKeyedBeacon(address(extrospect), address(impl), address(0));
        bytes32 expected = keccak256(address(impl).code);
        assertTrue(expected != keccak256(""));

        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), expected));
        assertFalse(extrospect.isBeaconImplementationBytecode(address(beacon), expected));
    }
}
