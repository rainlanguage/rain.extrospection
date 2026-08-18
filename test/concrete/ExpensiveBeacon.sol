// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IBeacon} from "src/interface/IBeacon.sol";
import {IOwnable} from "src/interface/IOwnable.sol";

/// @dev Gas an `ExpensiveBeacon` burns before it answers. Far above what
/// a minimal getter costs, so any cap on the gas the predicate forwards
/// below this leaves the beacon unable to answer.
uint256 constant EXPENSIVE_BEACON_GAS_BURN = 100_000;

/// @dev Honest beacon test fixture with an expensive getter. Reports its
/// implementation and owner truthfully, after burning
/// `EXPENSIVE_BEACON_GAS_BURN` gas. Reverts if called with less gas than
/// that. Pins that the predicate forwards all the gas it has, so the
/// cost of a beacon's getter does not change the verdict.
contract ExpensiveBeacon is IBeacon, IOwnable {
    address private immutable I_IMPLEMENTATION;
    address private immutable I_OWNER;

    constructor(address impl, address own) {
        I_IMPLEMENTATION = impl;
        I_OWNER = own;
    }

    function implementation() external view returns (address) {
        _burnGas();
        return I_IMPLEMENTATION;
    }

    function owner() external view returns (address) {
        _burnGas();
        return I_OWNER;
    }

    /// @dev Hashes scratch space in a loop until `EXPENSIVE_BEACON_GAS_BURN`
    /// gas has been spent.
    function _burnGas() internal view {
        uint256 gasFloor = gasleft() - EXPENSIVE_BEACON_GAS_BURN;
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            for {} gt(gas(), gasFloor) {} { mstore(0, keccak256(0, 0x20)) }
        }
    }
}
