// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the LOG2 opcode (event with 1 indexed param).
contract HasLog2 {
    event LogEvent(uint256 indexed a, uint256 value);

    function emitLog(uint256 a, uint256 v) external {
        emit LogEvent(a, v);
    }
}
