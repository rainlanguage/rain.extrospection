// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {LibExtrospectMetamorphic} from "src/lib/LibExtrospectMetamorphic.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";
import {RevertingBeacon} from "test/concrete/RevertingBeacon.sol";
import {BogusBeacon} from "test/concrete/BogusBeacon.sol";
import {WrongLengthBeacon} from "test/concrete/WrongLengthBeacon.sol";
import {HasSelfdestruct} from "test/concrete/HasSelfdestruct.sol";
import {NonMetamorphic} from "test/concrete/NonMetamorphic.sol";
import {
    RevertingWithAddressBeacon,
    REVERTING_WITH_ADDRESS_BEACON_PAYLOAD
} from "test/concrete/RevertingWithAddressBeacon.sol";

/// @title LibExtrospectERC1967BeaconProxyBeaconImplementationTest
/// @notice Tests `LibExtrospectERC1967BeaconProxy.beaconImplementation`.
contract LibExtrospectERC1967BeaconProxyBeaconImplementationTest is Test {
    /// Returns the address the beacon reports from `implementation()`.
    function testReturnsImplementation() external {
        EmptyContract impl = new EmptyContract();
        MockBeacon beacon = new MockBeacon(address(impl), address(this));
        (bool ok, address actual) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(beacon));
        assertTrue(ok);
        assertEq(actual, address(impl));
    }

    /// The implementation address is read from `implementation()`, not
    /// from `owner()`: a beacon whose two getters disagree yields the
    /// implementation.
    function testReadsImplementationNotOwner() external {
        EmptyContract impl = new EmptyContract();
        address own = address(uint160(0xBEEF));
        MockBeacon beacon = new MockBeacon(address(impl), own);
        (bool ok, address actual) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(beacon));
        assertTrue(ok);
        assertEq(actual, address(impl));
        assertTrue(actual != own);
    }

    /// A beacon reporting `address(0)` is a successful read of the zero
    /// address, not a failure.
    function testReturnsZeroImplementation() external {
        MockBeacon beacon = new MockBeacon(address(0), address(this));
        (bool ok, address actual) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(beacon));
        assertTrue(ok);
        assertEq(actual, address(0));
    }

    /// `address(type(uint160).max)` is the largest valid 160-bit
    /// address, accepted by the strict upper-bits check.
    function testReturnsMaxAddressImplementation() external {
        address maxAddr = address(type(uint160).max);
        MockBeacon beacon = new MockBeacon(maxAddr, address(this));
        (bool ok, address actual) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(beacon));
        assertTrue(ok);
        assertEq(actual, maxAddr);
    }

    /// A target that doesn't expose `implementation()` yields
    /// `(false, address(0))`.
    function testFalseOnNonBeacon() external {
        EmptyContract notABeacon = new EmptyContract();
        (bool ok, address actual) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(notABeacon));
        assertFalse(ok);
        assertEq(actual, address(0));
    }

    /// A beacon whose `implementation()` reverts yields
    /// `(false, address(0))`.
    function testFalseOnRevert() external {
        RevertingBeacon beacon = new RevertingBeacon();
        (bool ok, address actual) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(beacon));
        assertFalse(ok);
        assertEq(actual, address(0));
    }

    /// A beacon whose `implementation()` returns 32 bytes with non-zero
    /// upper 12 bytes yields `(false, address(0))` rather than the
    /// truncated low 160 bits.
    function testFalseOnDirtyAddress() external {
        BogusBeacon beacon = new BogusBeacon();
        (bool ok, address actual) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(beacon));
        assertFalse(ok);
        assertEq(actual, address(0));
        assertTrue(actual != address(type(uint160).max));
    }

    /// A beacon whose `implementation()` returns more than 32 bytes
    /// yields `(false, address(0))`, even though the first word
    /// (`0x20`, the offset of an empty `string memory`) decodes as a
    /// clean address.
    function testFalseOnWrongLengthReturn() external {
        WrongLengthBeacon beacon = new WrongLengthBeacon();
        (bool ok, address actual) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(beacon));
        assertFalse(ok);
        assertEq(actual, address(0));
        assertTrue(actual != address(uint160(0x20)));
    }

    /// `staticcall` to a no-code target returns success with empty
    /// returndata, which the length check rejects.
    function testFalseOnNoCodeTarget() external view {
        (bool ok, address actual) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(0));
        assertFalse(ok);
        assertEq(actual, address(0));
    }

    /// A beacon whose `implementation()` reverts with exactly 32 bytes
    /// that decode cleanly as an address yields `(false, address(0))`:
    /// only the staticcall's success flag separates this from a
    /// successful return of the same bytes.
    function testFalseOnRevertWithAddressSizedData() external {
        RevertingWithAddressBeacon beacon = new RevertingWithAddressBeacon();
        (bool ok, address actual) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(beacon));
        assertFalse(ok);
        assertEq(actual, address(0));
        assertTrue(actual != REVERTING_WITH_ADDRESS_BEACON_PAYLOAD);
    }

    /// The returned address composes with the repo's own bytecode
    /// checks: a beacon serving a `SELFDESTRUCT`-carrying
    /// implementation is rejected by `checkNotMetamorphic`, and one
    /// serving a clean implementation passes.
    function testComposesWithMetamorphicCheck() external {
        HasSelfdestruct risky = new HasSelfdestruct();
        MockBeacon riskyBeacon = new MockBeacon(address(risky), address(this));
        (bool riskyOk, address riskyImpl) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(riskyBeacon));
        assertTrue(riskyOk);
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(riskyImpl.code);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        this.externalCheckNotMetamorphic(riskyImpl.code);

        NonMetamorphic clean = new NonMetamorphic();
        MockBeacon cleanBeacon = new MockBeacon(address(clean), address(this));
        (bool cleanOk, address cleanImpl) = LibExtrospectERC1967BeaconProxy.beaconImplementation(address(cleanBeacon));
        assertTrue(cleanOk);
        this.externalCheckNotMetamorphic(cleanImpl.code);
    }

    /// @dev External hop so `vm.expectRevert` has a call boundary to
    /// attach to.
    function externalCheckNotMetamorphic(bytes memory bytecode) external pure {
        LibExtrospectMetamorphic.checkNotMetamorphic(bytecode);
    }
}
