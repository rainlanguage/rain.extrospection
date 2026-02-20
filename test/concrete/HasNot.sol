// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the NOT opcode.
contract HasNot {
    function doNot(uint256 a) external pure returns (uint256 result) {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            result := not(a)
        }
    }
}
