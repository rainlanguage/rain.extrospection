// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the CALLDATACOPY opcode.
contract HasCalldatacopy {
    function copy(bytes calldata data) external pure returns (bytes memory) {
        return data;
    }
}
