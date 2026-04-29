// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";
import {RevertingBeacon} from "test/concrete/RevertingBeacon.sol";

/// @title LibExtrospectERC1967BeaconProxyIsBeaconImplementationBytecodeTest
/// @notice Tests `LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode`.
contract LibExtrospectERC1967BeaconProxyIsBeaconImplementationBytecodeTest is Test {
    /// Returns true when the beacon's implementation runtime hashes to
    /// the expected value.
    function testMatches() external {
        EmptyContract impl = new EmptyContract();
        MockBeacon beacon = new MockBeacon(address(impl), address(this));
        assertTrue(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(
                address(beacon), keccak256(address(impl).code)
            )
        );
    }

    /// Returns false when the expected hash differs from the actual
    /// implementation runtime hash.
    function testMismatches(bytes32 wrongHash) external {
        EmptyContract impl = new EmptyContract();
        MockBeacon beacon = new MockBeacon(address(impl), address(this));
        vm.assume(wrongHash != keccak256(address(impl).code));
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), wrongHash));
    }

    /// A beacon whose `implementation()` returns `address(0)` resolves
    /// to an empty-code account; its hash is `keccak256("")`.
    function testImplementationZeroAddressHashesToEmpty(bytes32 wrongHash) external {
        bytes32 emptyHash = keccak256("");
        vm.assume(wrongHash != emptyHash);
        MockBeacon beacon = new MockBeacon(address(0), address(this));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), emptyHash));
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), wrongHash));
    }

    /// A target that doesn't expose `implementation()` is not a valid
    /// beacon and trivially fails the predicate. Returns false rather
    /// than reverting so integrators can collapse the check to a single
    /// boolean assertion.
    function testReturnsFalseOnNonBeacon(bytes32 expected) external {
        EmptyContract notABeacon = new EmptyContract();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(notABeacon), expected));
    }

    /// A beacon whose `implementation()` reverts is also a failure for
    /// the predicate, returning false rather than propagating.
    function testReturnsFalseOnBeaconRevert(bytes32 expected) external {
        RevertingBeacon beacon = new RevertingBeacon();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), expected));
    }
}
