// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that uses the LOG0 opcode (anonymous event, no topics).
contract HasLog0 {
    event AnonymousEvent(uint256 value) anonymous;

    function emitLog(uint256 v) external {
        emit AnonymousEvent(v);
    }
}
