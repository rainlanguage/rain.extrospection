// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the OR opcode.
contract HasOr {
    function doOr(uint256 a, uint256 b) external pure returns (uint256) {
        return a | b;
    }
}
