// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {
    ERC1967_IMPLEMENTATION_SLOT,
    ERC1967_ADMIN_SLOT,
    ERC1967_BEACON_SLOT
} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";

/// @dev Proxy test fixture that writes the three EIP-1967 slots in its
/// constructor, giving a known storage layout to read back. Stores each
/// address right-aligned in its 32-byte slot, matching how an EIP-1967
/// proxy lays out the slots. The constructor arguments fix the exact
/// address each slot holds so a test can assert the reader returns them.
contract ERC1967ProxyFixture {
    constructor(address implementation, address admin, address beacon) {
        bytes32 implementationSlot = ERC1967_IMPLEMENTATION_SLOT;
        bytes32 adminSlot = ERC1967_ADMIN_SLOT;
        bytes32 beaconSlot = ERC1967_BEACON_SLOT;
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            sstore(implementationSlot, implementation)
            sstore(adminSlot, admin)
            sstore(beaconSlot, beacon)
        }
    }
}
