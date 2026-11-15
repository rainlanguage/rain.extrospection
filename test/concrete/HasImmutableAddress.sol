// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract whose runtime code embeds a constructor-set address as an
/// immutable.
contract HasImmutableAddress {
    address internal immutable I_TARGET;

    //forge-lint: disable-next-line(missing-zero-check)
    constructor(address target) {
        I_TARGET = target;
    }

    function target() external view returns (address) {
        return I_TARGET;
    }
}
