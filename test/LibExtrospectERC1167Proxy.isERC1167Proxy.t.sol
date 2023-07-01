// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import "src/LibExtrospectERC1167Proxy.sol";

/// @title LibExtrospectERC1167ProxyTest
/// @notice Tests the LibExtrospectERC1167Proxy library.
contract LibExtrospectERC1167ProxyTest is Test {
    /// ERC1167 has known length so any other length is not a proxy.
    function testIsERC1167ProxyLength(bytes memory bytecode) external {
        vm.assume(bytecode.length != ERC1167_PROXY_LENGTH);
        (bool result, address implementation) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(!result);
        assertEq(implementation, address(0));
    }

    /// ERC1167 has known prefix so any other prefix is not a proxy.
    function testIsERC1167ProxyPrefixFail(bytes memory badPrefix, address implementation) external {
        vm.assume(keccak256(badPrefix) != keccak256(ERC1167_PREFIX));
        bytes memory bytecode = abi.encodePacked(badPrefix, implementation, ERC1167_SUFFIX);
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(!result);
        assertEq(implementationResult, address(0));
    }

    /// ERC1167 has known suffix so any other suffix is not a proxy.
    function testIsERC1167ProxySuffixFail(bytes memory badSuffix, address implementation) external {
        vm.assume(keccak256(badSuffix) != keccak256(ERC1167_SUFFIX));
        bytes memory bytecode = abi.encodePacked(ERC1167_PREFIX, implementation, badSuffix);
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(!result);
        assertEq(implementationResult, address(0));
    }

    /// The correct implementation of ERC1167 is detected as a proxy and the
    /// implementation address is returned.
    function testIsERC1167ProxySuccess(address implementation) external {
        bytes memory bytecode = abi.encodePacked(ERC1167_PREFIX, implementation, ERC1167_SUFFIX);
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(result);
        assertEq(implementationResult, implementation);
    }
}
