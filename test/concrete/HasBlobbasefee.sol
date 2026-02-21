// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the BLOBBASEFEE opcode.
contract HasBlobbasefee {
    function getBlobbasefee() external view returns (uint256) {
        return block.blobbasefee;
    }
}
