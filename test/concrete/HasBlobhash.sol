// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the BLOBHASH opcode.
contract HasBlobhash {
    function getBlobhash(uint256 idx) external view returns (bytes32) {
        return blobhash(idx);
    }
}
