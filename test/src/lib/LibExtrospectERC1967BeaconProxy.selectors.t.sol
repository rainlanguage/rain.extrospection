// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {LibExtrospectERC1967BeaconProxy} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";
import {EmptyContract} from "test/concrete/EmptyContract.sol";
import {NonMetamorphic} from "test/concrete/NonMetamorphic.sol";

bytes4 constant PUBLISHED_IMPLEMENTATION_SELECTOR = 0x5c60da1b;
bytes4 constant PUBLISHED_OWNER_SELECTOR = 0x8da5cb5b;

contract LibExtrospectERC1967BeaconProxySelectorsTest is Test {
    /// `beaconImplementation` reads a beacon that answers only the published `implementation()` selector.
    function testBeaconImplementationSendsPublishedImplementationSelector() external {
        address beacon = address(new EmptyContract());
        address implementation = address(uint160(0x1A1A));
        vm.mockCall(beacon, abi.encodePacked(PUBLISHED_IMPLEMENTATION_SELECTOR), abi.encode(implementation));
        (bool ok, address actual) = LibExtrospectERC1967BeaconProxy.beaconImplementation(beacon);
        assertTrue(ok);
        assertEq(actual, implementation);
    }

    /// `isBeaconImplementationBytecode` reads a beacon that answers only the published `implementation()` selector.
    function testIsBeaconImplementationBytecodeSendsPublishedImplementationSelector() external {
        address beacon = address(new EmptyContract());
        address implementation = address(new NonMetamorphic());
        vm.mockCall(beacon, abi.encodePacked(PUBLISHED_IMPLEMENTATION_SELECTOR), abi.encode(implementation));
        assertTrue(
            LibExtrospectERC1967BeaconProxy.isBeaconImplementationBytecode(beacon, keccak256(implementation.code))
        );
    }

    /// `isBeaconOwner` reads a beacon that answers only the published `owner()` selector.
    function testIsBeaconOwnerSendsPublishedOwnerSelector() external {
        address beacon = address(new EmptyContract());
        address owner = address(uint160(0x0FFE));
        vm.mockCall(beacon, abi.encodePacked(PUBLISHED_OWNER_SELECTOR), abi.encode(owner));
        assertTrue(LibExtrospectERC1967BeaconProxy.isBeaconOwner(beacon, owner));
    }
}
