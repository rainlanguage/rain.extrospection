// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev Child contract deployed by `CreateChildFactory` and
/// `Create2ChildFactory`. Contains no metamorphic risk opcodes.
contract ChildLeaf {
    function value() external pure returns (uint256) {
        return 1;
    }
}
