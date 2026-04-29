// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {
    ERC1967_IMPLEMENTATION_SLOT,
    ERC1967_ADMIN_SLOT,
    ERC1967_BEACON_SLOT
} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";

/// @title LibExtrospectERC1967BeaconProxySlotsTest
/// @notice Pins the EIP-1967 slot constant derivations.
contract LibExtrospectERC1967BeaconProxySlotsTest is Test {
    /// `ERC1967_IMPLEMENTATION_SLOT` matches `keccak256("eip1967.proxy.implementation") - 1`.
    function testImplementationSlotMatchesDerivation() external pure {
        assertEq(ERC1967_IMPLEMENTATION_SLOT, bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    }

    /// `ERC1967_ADMIN_SLOT` matches `keccak256("eip1967.proxy.admin") - 1`.
    function testAdminSlotMatchesDerivation() external pure {
        assertEq(ERC1967_ADMIN_SLOT, bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
    }

    /// `ERC1967_BEACON_SLOT` matches `keccak256("eip1967.proxy.beacon") - 1`.
    function testBeaconSlotMatchesDerivation() external pure {
        assertEq(ERC1967_BEACON_SLOT, bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
    }

    /// The three EIP-1967 slots are pairwise distinct.
    function testSlotsAreDistinct() external pure {
        assertTrue(ERC1967_IMPLEMENTATION_SLOT != ERC1967_ADMIN_SLOT);
        assertTrue(ERC1967_IMPLEMENTATION_SLOT != ERC1967_BEACON_SLOT);
        assertTrue(ERC1967_ADMIN_SLOT != ERC1967_BEACON_SLOT);
    }
}
