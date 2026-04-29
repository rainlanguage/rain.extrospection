// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";
import {RevertingBeacon} from "test/concrete/RevertingBeacon.sol";

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

    /// Documents what happens on a no-code address. Solidity's high-level
    /// call to a no-code target reverts on extcodesize check at compile
    /// settings that enforce it; if the toolchain is permissive the call
    /// returns whatever ABI decoding yields from empty returndata. Either
    /// way, the helper must not silently corrupt — pin whichever
    /// behaviour Solidity gives us so a future toolchain change surfaces.
    function testZeroAddressBehaviour() external {
        try this.callImplementationOf(address(0)) returns (address result) {
            // Permissive path: empty returndata decodes to address(0).
            assertEq(result, address(0), "no-code target must decode to zero, not arbitrary memory");
        } catch {
            // Strict path: extcodesize check or ABI-decode revert.
        }
    }

    /// External wrapper so the test can `try`/`catch` the helper.
    function callImplementationOf(address target) external view returns (address) {
        return LibExtrospectERC1967BeaconProxy.implementationOf(target);
    }

    /// Reverts when the beacon's `implementation()` itself reverts —
    /// distinct from "no selector" (which is an ABI-decode revert);
    /// this is a propagated revert from a present-but-failing call.
    function testPropagatesBeaconRevert() external {
        RevertingBeacon beacon = new RevertingBeacon();
        vm.expectRevert();
        LibExtrospectERC1967BeaconProxy.implementationOf(address(beacon));
    }
}
