// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Clean contract with no metamorphic risk opcodes.
contract CleanContract {
    uint256 public value;

    function set(uint256 v) external {
        value = v;
    }
}
