// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {
    LibExtrospectERC1967BeaconProxy,
    ERC1967_IMPLEMENTATION_SLOT,
    ERC1967_ADMIN_SLOT,
    ERC1967_BEACON_SLOT
} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";

/// @dev Minimal mock beacon exposing both `implementation()` and
/// `owner()` so the lib's interface-based helpers have something
/// concrete to call.
contract MockBeacon {
    address public immutable implementation;
    address public immutable owner;

    constructor(address impl, address own) {
        implementation = impl;
        owner = own;
    }
}

/// @dev Beacon that lacks both interface functions — calls revert.
contract EmptyContract {}

/// @title LibExtrospectERC1967BeaconProxyTest
/// @notice Tests slot-constant derivations and the interface-based
/// helpers for reading beacon state.
contract LibExtrospectERC1967BeaconProxyTest is Test {
    /// `ERC1967_IMPLEMENTATION_SLOT` matches the EIP-1967 derivation
    /// `keccak256("eip1967.proxy.implementation") - 1`.
    function testImplementationSlotMatchesDerivation() external pure {
        assertEq(ERC1967_IMPLEMENTATION_SLOT, bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    }

    /// `ERC1967_ADMIN_SLOT` matches the EIP-1967 derivation
    /// `keccak256("eip1967.proxy.admin") - 1`.
    function testAdminSlotMatchesDerivation() external pure {
        assertEq(ERC1967_ADMIN_SLOT, bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
    }

    /// `ERC1967_BEACON_SLOT` matches the EIP-1967 derivation
    /// `keccak256("eip1967.proxy.beacon") - 1`.
    function testBeaconSlotMatchesDerivation() external pure {
        assertEq(ERC1967_BEACON_SLOT, bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
    }

    /// The three EIP-1967 slots are pairwise distinct.
    function testSlotsAreDistinct() external pure {
        assertTrue(ERC1967_IMPLEMENTATION_SLOT != ERC1967_ADMIN_SLOT);
        assertTrue(ERC1967_IMPLEMENTATION_SLOT != ERC1967_BEACON_SLOT);
        assertTrue(ERC1967_ADMIN_SLOT != ERC1967_BEACON_SLOT);
    }

    /// `implementationOf` returns the `implementation()` value reported
    /// by the beacon.
    function testImplementationOfReturnsBeaconImplementation(address impl, address own) external {
        MockBeacon beacon = new MockBeacon(impl, own);
        assertEq(LibExtrospectERC1967BeaconProxy.implementationOf(address(beacon)), impl);
    }

    /// `ownerOf` returns the `owner()` value reported by the beacon.
    function testOwnerOfReturnsBeaconOwner(address impl, address own) external {
        MockBeacon beacon = new MockBeacon(impl, own);
        assertEq(LibExtrospectERC1967BeaconProxy.ownerOf(address(beacon)), own);
    }

    /// `implementationOf` reverts when the target doesn't expose the
    /// `implementation()` selector.
    function testImplementationOfRevertsOnNonBeacon() external {
        EmptyContract notABeacon = new EmptyContract();
        vm.expectRevert();
        LibExtrospectERC1967BeaconProxy.implementationOf(address(notABeacon));
    }

    /// `ownerOf` reverts when the target doesn't expose the `owner()`
    /// selector.
    function testOwnerOfRevertsOnNonOwnable() external {
        EmptyContract notOwnable = new EmptyContract();
        vm.expectRevert();
        LibExtrospectERC1967BeaconProxy.ownerOf(address(notOwnable));
    }

    /// `isBeaconImplementationBytecode` returns true when the beacon's
    /// implementation has the expected runtime bytecode.
    function testIsBeaconImplementationBytecodeMatches() external {
        EmptyContract impl = new EmptyContract();
        MockBeacon beacon = new MockBeacon(address(impl), address(this));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), keccak256(address(impl).code)));
    }

    /// `isBeaconImplementationBytecode` returns false when the beacon's
    /// implementation has different runtime bytecode.
    function testIsBeaconImplementationBytecodeMismatches(bytes32 wrongHash) external {
        EmptyContract impl = new EmptyContract();
        MockBeacon beacon = new MockBeacon(address(impl), address(this));
        vm.assume(wrongHash != keccak256(address(impl).code));
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(address(beacon), wrongHash));
    }

    /// `isRuntimeBytecode` returns true for an exact match.
    function testIsRuntimeBytecodeMatches() external {
        EmptyContract target = new EmptyContract();
        assertTrue(LibExtrospectERC1967BeaconProxy.isRuntimeBytecode(address(target), keccak256(address(target).code)));
    }

    /// `isRuntimeBytecode` returns false for a non-matching expected hash.
    function testIsRuntimeBytecodeMismatches(bytes32 wrongHash) external {
        EmptyContract target = new EmptyContract();
        vm.assume(wrongHash != keccak256(address(target).code));
        assertFalse(LibExtrospectERC1967BeaconProxy.isRuntimeBytecode(address(target), wrongHash));
    }

    /// `isBeaconOwner` returns true when the beacon's reported owner
    /// matches.
    function testIsBeaconOwnerMatches(address impl, address own) external {
        MockBeacon beacon = new MockBeacon(impl, own);
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), own));
    }

    /// `isBeaconOwner` returns false on a mismatch.
    function testIsBeaconOwnerMismatches(address impl, address own, address wrong) external {
        vm.assume(wrong != own);
        MockBeacon beacon = new MockBeacon(impl, own);
        assertFalse(LibExtrospectERC1967BeaconProxy.isBeaconOwner(address(beacon), wrong));
    }
}
