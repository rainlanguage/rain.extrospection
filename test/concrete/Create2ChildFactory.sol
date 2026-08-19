// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ChildLeaf} from "./ChildLeaf.sol";

/// @dev Contract that uses CREATE2 to deploy a single fixed child type. Its own
/// runtime code contains no SELFDESTRUCT, DELEGATECALL or CALLCODE.
contract Create2ChildFactory {
    function make(bytes32 salt) external returns (address) {
        return address(new ChildLeaf{salt: salt}());
    }
}
