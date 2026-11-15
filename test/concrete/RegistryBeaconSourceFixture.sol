// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {BEACON_BINDING_VALUE_TYPE_HASH} from "test/lib/LibExtrospectRegistryBeaconProxy.testConstants.sol";

/// @dev Config registry stand-in that binds every name under every authority
/// to `beacon`, so a `RegistryBeaconProxy` constructed against it resolves
/// `beacon`.
contract RegistryBeaconSourceFixture {
    address internal immutable iBeacon;

    // A zero beacon is a binding the tests may resolve.
    //forge-lint: disable-next-line(missing-zero-check)
    constructor(address beacon) {
        iBeacon = beacon;
    }

    function getV5(address, bytes32) external view returns (bytes memory, uint256, bytes32) {
        return (abi.encode(iBeacon), block.timestamp, BEACON_BINDING_VALUE_TYPE_HASH);
    }
}
