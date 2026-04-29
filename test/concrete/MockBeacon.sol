// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Minimal beacon test fixture. Exposes both `implementation()`
/// and `owner()` so the lib's interface-based helpers have something
/// concrete to call.
contract MockBeacon {
    address public immutable implementation;
    address public immutable owner;

    constructor(address impl, address own) {
        implementation = impl;
        owner = own;
    }
}
