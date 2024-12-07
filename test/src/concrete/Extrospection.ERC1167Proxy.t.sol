// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibExtrospectERC1167Proxy, ERC1167_PREFIX, ERC1167_SUFFIX} from "src/lib/LibExtrospectERC1167Proxy.sol";

import {Extrospection} from "src/concrete/Extrospection.sol";

/// @title ExtrospectionERC1167ProxyTest
/// @notice Tests the Extrospection contract implementation of
/// `IExtrospectERC1167ProxyV1`.
contract ExtrospectionERC1167ProxyTest is Test {
    /// Test that we can reliably detect that something is NOT a proxy and that
    /// implementation is always `address(0)` in that case.
    function testExtrospectionERC1167ProxyFailure(address proxy, bytes memory bytecode) external {
        // Ensure that the bytecode doesn't somehow magically fuzz itself into
        // a valid proxy. The main thing we want to test is that the concrete
        // contract agrees with the library.
        (bool bytecodeIsProxy,) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        vm.assume(!bytecodeIsProxy);

        Extrospection extrospection = new Extrospection();

        // Proxy can't be extrospection, otherwise we'll etch over it.
        vm.assume(proxy != address(extrospection));
        // Proxy can't be a precompile either.
        vm.assume(uint160(proxy) > 10);
        // Force incorrect proxy implementation into the proxy address.
        vm.etch(proxy, bytecode);

        (bool result, address implementation) = extrospection.isERC1167Proxy(proxy);
        assertTrue(!result);
        assertEq(implementation, address(0));
    }

    /// Test that we can reliably detect that something IS a proxy and that
    /// implementation can be extracted.
    function testExtrospectionERC1167ProxySuccess(address implementation, address proxy) external {
        Extrospection extrospection = new Extrospection();

        // Proxy can't be extrospection, otherwise we'll etch over it.
        vm.assume(proxy != address(extrospection));
        // Proxy can't be a precompile either.
        vm.assume(uint160(proxy) > 10);
        // Force correct proxy implementation into the proxy address.
        vm.etch(proxy, abi.encodePacked(ERC1167_PREFIX, implementation, ERC1167_SUFFIX));

        (bool result, address implementationResult) = extrospection.isERC1167Proxy(proxy);
        assertTrue(result);
        assertEq(implementationResult, implementation);
    }
}
