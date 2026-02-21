// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the BLOCKHASH opcode.
contract HasBlockhash {
    function getBlockhash(uint256 n) external view returns (bytes32) {
        return blockhash(n);
    }
}
