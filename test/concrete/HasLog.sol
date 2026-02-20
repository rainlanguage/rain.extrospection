// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Contract that emits a log (LOG1 via a Solidity event).
contract HasLog {
    event LogEvent(uint256 value);

    function emitLog(uint256 v) external {
        emit LogEvent(v);
    }
}
