// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibExtrospectERC1967ProxySlots} from "test/lib/LibExtrospectERC1967ProxySlots.sol";
import {ERC1967ProxyFixture} from "test/concrete/ERC1967ProxyFixture.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";

/// @title LibExtrospectERC1967ProxySlotsTest
/// @notice Tests `LibExtrospectERC1967ProxySlots` reads each EIP-1967
/// proxy slot back to the exact address written.
contract LibExtrospectERC1967ProxySlotsTest is Test {
    /// Each reader returns the exact address the fixture wrote to its
    /// slot. The three addresses are distinct so a reader that read the
    /// wrong slot would return a different value.
    function testReadsKnownSlotLayout() external {
        address implementation = address(0x1111111111111111111111111111111111111111);
        address admin = address(0x2222222222222222222222222222222222222222);
        address beacon = address(0x3333333333333333333333333333333333333333);
        ERC1967ProxyFixture proxy = new ERC1967ProxyFixture(implementation, admin, beacon);

        assertEq(LibExtrospectERC1967ProxySlots.erc1967Implementation(vm, address(proxy)), implementation);
        assertEq(LibExtrospectERC1967ProxySlots.erc1967Admin(vm, address(proxy)), admin);
        assertEq(LibExtrospectERC1967ProxySlots.erc1967Beacon(vm, address(proxy)), beacon);
    }

    /// Fuzzed layout: each reader returns the exact address written to
    /// its own slot, independent of the other two.
    function testReadsFuzzedSlotLayout(address implementation, address admin, address beacon) external {
        ERC1967ProxyFixture proxy = new ERC1967ProxyFixture(implementation, admin, beacon);

        assertEq(LibExtrospectERC1967ProxySlots.erc1967Implementation(vm, address(proxy)), implementation);
        assertEq(LibExtrospectERC1967ProxySlots.erc1967Admin(vm, address(proxy)), admin);
        assertEq(LibExtrospectERC1967ProxySlots.erc1967Beacon(vm, address(proxy)), beacon);
    }

    /// A non-proxy never wrote the slots, so every reader returns the
    /// zero address the slot defaults to.
    function testReadsZeroFromNonProxy() external {
        EmptyContract notAProxy = new EmptyContract();

        assertEq(LibExtrospectERC1967ProxySlots.erc1967Implementation(vm, address(notAProxy)), address(0));
        assertEq(LibExtrospectERC1967ProxySlots.erc1967Admin(vm, address(notAProxy)), address(0));
        assertEq(LibExtrospectERC1967ProxySlots.erc1967Beacon(vm, address(notAProxy)), address(0));
    }

    /// Reading a slot only reflects that slot: a layout where only one
    /// slot is set leaves the other two zero. Pins that the readers do
    /// not alias each other's slot.
    function testReadsOnlyImplementationSlot() external {
        address implementation = address(0x4444444444444444444444444444444444444444);
        ERC1967ProxyFixture proxy = new ERC1967ProxyFixture(implementation, address(0), address(0));

        assertEq(LibExtrospectERC1967ProxySlots.erc1967Implementation(vm, address(proxy)), implementation);
        assertEq(LibExtrospectERC1967ProxySlots.erc1967Admin(vm, address(proxy)), address(0));
        assertEq(LibExtrospectERC1967ProxySlots.erc1967Beacon(vm, address(proxy)), address(0));
    }
}
