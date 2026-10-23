// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IRegistryBeaconSourceV1} from "rain-factory-0.2.5/src/lib/LibICloneableFactoryV6.sol";

/// @dev Config registry stand-in that binds every name under every authority
/// to `beacon`, so a `RegistryBeaconProxy` constructed against it resolves
/// `beacon`.
contract RegistryBeaconSourceFixture is IRegistryBeaconSourceV1 {
    address internal immutable iBeacon;

    // A zero beacon is a binding the tests may resolve.
    //forge-lint: disable-next-line(missing-zero-check)
    constructor(address beacon) {
        iBeacon = beacon;
    }

    function getV3(address, bytes32) external view returns (bytes memory, uint256) {
        return (abi.encode(iBeacon), block.timestamp);
    }
}
