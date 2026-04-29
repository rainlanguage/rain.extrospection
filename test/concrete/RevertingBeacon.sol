// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IBeacon} from "src/interface/IBeacon.sol";
import {IOwnable} from "src/interface/IOwnable.sol";

/// @dev Beacon test fixture whose `implementation()` and `owner()`
/// selectors exist but revert. Distinguishes the "selector missing"
/// case (covered by `EmptyContract`) from the "selector present but
/// failing" case during interface dispatch.
contract RevertingBeacon is IBeacon, IOwnable {
    error BeaconCallReverted();

    function implementation() external pure returns (address) {
        revert BeaconCallReverted();
    }

    function owner() external pure returns (address) {
        revert BeaconCallReverted();
    }
}
