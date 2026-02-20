// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the SHA3 (KECCAK256) opcode.
contract HasSha3 {
    function hash(uint256 x) external pure returns (bytes32) {
        return keccak256(abi.encode(x));
    }
}
