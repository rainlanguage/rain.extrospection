// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";
import {RevertingBeacon} from "test/concrete/RevertingBeacon.sol";
import {BogusBeacon} from "test/concrete/BogusBeacon.sol";
import {WrongLengthBeacon} from "test/concrete/WrongLengthBeacon.sol";

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

    /// Pins the `ok && ...` short-circuit at its boundary value:
    /// `expected = keccak256("")` is exactly `keccak256(address(0).code)`.
    /// Without the `ok &&` guard, the predicate would still compute
    /// `keccak256(address(0).code) == expected` after a failed call and
    /// return true, falsely accepting any non-beacon as a beacon
    /// pointing at empty code. The non-fuzz form catches that
    /// specifically; fuzz expecteds hit `keccak256("")` with
    /// probability 1/2^256.
    function testReturnsFalseOnNonBeaconWithEmptyHash() external {
        EmptyContract notABeacon = new EmptyContract();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(notABeacon), keccak256("")));
    }

    /// A beacon whose `implementation()` reverts is also a failure for
    /// the predicate, returning false rather than propagating.
    function testReturnsFalseOnBeaconRevert(bytes32 expected) external {
        RevertingBeacon beacon = new RevertingBeacon();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), expected));
    }

    /// A beacon whose `implementation()` returns bytes that don't
    /// decode as an `address` is also a failure for the predicate.
    /// High-level `try IBeacon(...).implementation() returns (address)`
    /// lets the dirty-address Panic escape past `catch`, so the
    /// wrapper goes through a low-level staticcall and rejects
    /// 32-byte returndata whose upper 12 bytes are non-zero.
    function testReturnsFalseOnInvalidReturnEncoding(bytes32 expected) external {
        BogusBeacon beacon = new BogusBeacon();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), expected));
    }

    /// `address(type(uint160).max)` is the largest valid 160-bit
    /// address — the strict upper-bits check (`raw > type(uint160).max`)
    /// must accept it, not reject it. Pins the boundary against a
    /// `>` → `>=` mutation that would falsely reject.
    function testMatchesAtMaxAddressBoundary() external {
        address maxAddr = address(type(uint160).max);
        MockBeacon beacon = new MockBeacon(maxAddr, address(this));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), keccak256(maxAddr.code)));
    }

    /// A beacon whose `implementation()` returns more than 32 bytes
    /// must also fail the predicate, even if the first 32 bytes
    /// happen to decode as a valid address. The expected hash here is
    /// `keccak256("")`, which is what the first 32 bytes of an empty
    /// `string memory` (the offset, `0x20`) would resolve to under a
    /// length-stripped impl — pinning the length check separately
    /// from the dirty-bits check.
    function testReturnsFalseOnWrongLengthReturn() external {
        WrongLengthBeacon beacon = new WrongLengthBeacon();
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), keccak256("")));
    }
}
