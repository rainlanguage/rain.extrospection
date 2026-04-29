// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IBeacon} from "src/interface/IBeacon.sol";
import {IOwnable} from "src/interface/IOwnable.sol";

/// @dev Minimal beacon test fixture implementing both `IBeacon` and
/// `IOwnable` so selector and return-type match the lib's expectations
/// at compile time.
contract MockBeacon is IBeacon, IOwnable {
    address public immutable implementation;
    address public immutable owner;

    constructor(address impl, address own) {
        implementation = impl;
        owner = own;
    }
}
