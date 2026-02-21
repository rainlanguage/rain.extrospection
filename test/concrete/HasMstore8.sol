// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the MSTORE8 opcode.
contract HasMstore8 {
    function doMstore8(uint8 value) external pure returns (bytes32 result) {
        //forge-lint: disable-next-line(assembly-usage)
        assembly {
            mstore8(0, value)
            result := mload(0)
        }
    }
}
