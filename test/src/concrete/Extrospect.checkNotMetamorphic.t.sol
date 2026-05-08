// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";
import {LibExtrospectMetamorphic} from "src/lib/LibExtrospectMetamorphic.sol";

contract ExtrospectCheckNotMetamorphicTest is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }

    function libCheckNotMetamorphicExternal(bytes memory bytecode) external pure {
        LibExtrospectMetamorphic.checkNotMetamorphic(bytecode);
    }

    function testCheckNotMetamorphicEquivalencePass() external view {
        bytes memory clean = hex"60016002F3";
        extrospect.checkNotMetamorphic(clean);
        LibExtrospectMetamorphic.checkNotMetamorphic(clean);
    }

    function testCheckNotMetamorphicEquivalenceRevert() external {
        bytes memory withDelegatecall = hex"60006000600060006000F4";
        vm.expectRevert();
        extrospect.checkNotMetamorphic(withDelegatecall);
        vm.expectRevert();
        this.libCheckNotMetamorphicExternal(withDelegatecall);
    }
}
