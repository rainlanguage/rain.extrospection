// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {
    ERC1967_IMPLEMENTATION_SLOT,
    ERC1967_ADMIN_SLOT,
    ERC1967_BEACON_SLOT
} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";

/// @dev The implementation slot literal published in EIP-1967.
/// https://eips.ethereum.org/EIPS/eip-1967#logic-contract-address
bytes32 constant EIP1967_PUBLISHED_IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

/// @dev The admin slot literal published in EIP-1967.
/// https://eips.ethereum.org/EIPS/eip-1967#admin-address
bytes32 constant EIP1967_PUBLISHED_ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

/// @dev The beacon slot literal published in EIP-1967.
/// https://eips.ethereum.org/EIPS/eip-1967#beacon-contract-address
bytes32 constant EIP1967_PUBLISHED_BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

/// @title LibExtrospectERC1967BeaconProxySlotsTest
/// @notice Pins the EIP-1967 slot constants to the slot literals published in
/// EIP-1967.
contract LibExtrospectERC1967BeaconProxySlotsTest is Test {
    /// `ERC1967_IMPLEMENTATION_SLOT` equals the published implementation slot.
    function testImplementationSlotMatchesPublishedLiteral() external pure {
        assertEq(ERC1967_IMPLEMENTATION_SLOT, EIP1967_PUBLISHED_IMPLEMENTATION_SLOT);
    }

    /// `ERC1967_ADMIN_SLOT` equals the published admin slot.
    function testAdminSlotMatchesPublishedLiteral() external pure {
        assertEq(ERC1967_ADMIN_SLOT, EIP1967_PUBLISHED_ADMIN_SLOT);
    }

    /// `ERC1967_BEACON_SLOT` equals the published beacon slot.
    function testBeaconSlotMatchesPublishedLiteral() external pure {
        assertEq(ERC1967_BEACON_SLOT, EIP1967_PUBLISHED_BEACON_SLOT);
    }

    /// The three EIP-1967 slots are pairwise distinct.
    function testSlotsAreDistinct() external pure {
        assertTrue(ERC1967_IMPLEMENTATION_SLOT != ERC1967_ADMIN_SLOT);
        assertTrue(ERC1967_IMPLEMENTATION_SLOT != ERC1967_BEACON_SLOT);
        assertTrue(ERC1967_ADMIN_SLOT != ERC1967_BEACON_SLOT);
    }
}
