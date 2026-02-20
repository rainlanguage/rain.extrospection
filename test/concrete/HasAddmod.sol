// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the ADDMOD opcode.
contract HasAddmod {
    function doAddmod(uint256 a, uint256 b, uint256 n) external pure returns (uint256) {
        return addmod(a, b, n);
    }
}
