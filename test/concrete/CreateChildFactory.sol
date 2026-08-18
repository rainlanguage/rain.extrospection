// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ChildLeaf} from "./ChildLeaf.sol";

/// @dev Contract that uses CREATE to deploy a single fixed child type. Its own
/// runtime code contains no SELFDESTRUCT, DELEGATECALL or CALLCODE.
contract CreateChildFactory {
    function make() external returns (address) {
        return address(new ChildLeaf());
    }
}
