// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the CHAINID opcode.
contract HasChainid {
    function getChainid() external view returns (uint256) {
        return block.chainid;
    }
}
