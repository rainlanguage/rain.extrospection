// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {Vm} from "forge-std-1.16.1/src/StdCheats.sol";
import {
    ERC1967_IMPLEMENTATION_SLOT,
    ERC1967_ADMIN_SLOT,
    ERC1967_BEACON_SLOT
} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";

/// @title LibExtrospectERC1967ProxySlots
/// @notice Foundry-only test utilities that read the three EIP-1967
/// proxy storage slots of an arbitrary address via `vm.load`.
///
/// ERC-1967 specifies the implementation, admin and beacon storage
/// slots but no public getter for any of them: a proxy routes every
/// call through `delegatecall`, so no function selector exposes the
/// slot. Direct reads come from `vm.load` (tests), an off-chain
/// `eth_getStorageAt`, or `sload` from a delegatecall context running
/// as the proxy. This library is the `vm.load` route, packaged so
/// consumers writing their own Foundry tests have a single canonical
/// reader for all three slots rather than re-deriving slot addresses
/// and address decoding at each call site.
///
/// Each slot stores an address right-aligned in a 32-byte word, so the
/// reader returns the low 160 bits as `address`. The slot constants
/// are imported from `LibExtrospectERC1967BeaconProxy` so this reader
/// and the on-chain library share one source for the slot addresses.
library LibExtrospectERC1967ProxySlots {
    /// @notice Read `proxy`'s EIP-1967 implementation slot.
    /// @param vm The Foundry cheatcode interface.
    /// @param proxy The proxy address whose storage is read.
    /// @return The address stored in the implementation slot. Zero if
    /// the slot was never written (e.g. the address is not an
    /// EIP-1967 proxy).
    function erc1967Implementation(Vm vm, address proxy) internal view returns (address) {
        return address(uint160(uint256(vm.load(proxy, ERC1967_IMPLEMENTATION_SLOT))));
    }

    /// @notice Read `proxy`'s EIP-1967 admin slot.
    /// @param vm The Foundry cheatcode interface.
    /// @param proxy The proxy address whose storage is read.
    /// @return The address stored in the admin slot. Zero if the slot
    /// was never written (e.g. the address is not an EIP-1967 proxy,
    /// or is a beacon proxy that has no admin).
    function erc1967Admin(Vm vm, address proxy) internal view returns (address) {
        return address(uint160(uint256(vm.load(proxy, ERC1967_ADMIN_SLOT))));
    }

    /// @notice Read `proxy`'s EIP-1967 beacon slot.
    /// @param vm The Foundry cheatcode interface.
    /// @param proxy The proxy address whose storage is read.
    /// @return The address stored in the beacon slot. Zero if the slot
    /// was never written (e.g. the address is not an EIP-1967 beacon
    /// proxy).
    function erc1967Beacon(Vm vm, address proxy) internal view returns (address) {
        return address(uint160(uint256(vm.load(proxy, ERC1967_BEACON_SLOT))));
    }
}
