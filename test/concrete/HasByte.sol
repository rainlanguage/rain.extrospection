// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the BYTE opcode.
contract HasByte {
    function getByte(uint256 i, uint256 x) external pure returns (uint256 result) {
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            result := byte(i, x)
        }
    }
}
