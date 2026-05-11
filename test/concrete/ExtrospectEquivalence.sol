// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";

/// @dev Abstract base for the per-function equivalence tests under
/// `test/src/concrete/Extrospect.<fn>.t.sol`. Each concrete test
/// inherits this for the shared `Extrospect` instance and `setUp`.
abstract contract ExtrospectEquivalence is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }
}
