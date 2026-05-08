// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";
import {LibExtrospectERC1167Proxy} from "src/lib/LibExtrospectERC1167Proxy.sol";

contract ExtrospectIsERC1167ProxyTest is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }

    function testIsERC1167ProxyEquivalenceFuzz(bytes memory bytecode) external view {
        (bool extIsProxy, address extImpl) = extrospect.isERC1167Proxy(bytecode);
        (bool libIsProxy, address libImpl) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertEq(extIsProxy, libIsProxy);
        assertEq(extImpl, libImpl);
    }

    function testIsERC1167ProxyEquivalenceEmpty() external view {
        (bool extIsProxy, address extImpl) = extrospect.isERC1167Proxy(hex"");
        (bool libIsProxy, address libImpl) = LibExtrospectERC1167Proxy.isERC1167Proxy(hex"");
        assertEq(extIsProxy, libIsProxy);
        assertEq(extImpl, libImpl);
    }
}
