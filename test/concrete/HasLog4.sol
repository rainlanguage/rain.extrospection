// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the LOG4 opcode (event with 3 indexed params).
contract HasLog4 {
    event LogEvent(uint256 indexed a, uint256 indexed b, uint256 indexed c, uint256 value);

    function emitLog(uint256 a, uint256 b, uint256 c, uint256 v) external {
        emit LogEvent(a, b, c, v);
    }
}
