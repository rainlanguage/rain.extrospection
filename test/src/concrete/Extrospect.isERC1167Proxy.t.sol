// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
import {LibExtrospectERC1167Proxy} from "src/lib/LibExtrospectERC1167Proxy.sol";

contract ExtrospectIsERC1167ProxyTest is ExtrospectEquivalence {
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

    /// A well-formed ERC1167 proxy: the concrete must return the implementation
    /// address embedded in the bytecode, not just the boolean. A delegation
    /// that dropped the second return component would yield address(0) here.
    function testIsERC1167ProxyConcreteImplementationAddress() external view {
        address expectedImplementation = address(0x00112233445566778899AABbCCdDeeFf00112233);
        bytes memory proxy =
            abi.encodePacked(hex"363d3d373d3d3d363d73", expectedImplementation, hex"5af43d82803e903d91602b57fd5bf3");
        assertEq(proxy.length, 45);
        (bool extIsProxy, address extImpl) = extrospect.isERC1167Proxy(proxy);
        assertTrue(extIsProxy);
        assertEq(extImpl, expectedImplementation);
    }
}
