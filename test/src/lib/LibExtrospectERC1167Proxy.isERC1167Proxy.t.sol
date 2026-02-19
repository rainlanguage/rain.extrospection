// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {
    LibExtrospectERC1167Proxy,
    ERC1167_SUFFIX,
    ERC1167_PREFIX,
    ERC1167_PROXY_LENGTH,
    ERC1167_PREFIX_LENGTH,
    ERC1167_SUFFIX_LENGTH
} from "src/lib/LibExtrospectERC1167Proxy.sol";
import {LibExtrospectionSlow} from "test/lib/LibExtrospectionSlow.sol";

/// @title LibExtrospectERC1167ProxyTest
/// @notice Tests the LibExtrospectERC1167Proxy library.
contract LibExtrospectERC1167ProxyTest is Test {
    /// ERC1167 has known length so any other length is not a proxy.
    function testIsERC1167ProxyLength(bytes memory bytecode) external pure {
        vm.assume(bytecode.length != ERC1167_PROXY_LENGTH);
        (bool result, address implementation) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(!result);
        assertEq(implementation, address(0));
    }

    /// ERC1167 has known prefix so any other prefix is not a proxy.
    /// Does NOT constrain length -- tests the length-check early return.
    function testIsERC1167ProxyPrefixFail(bytes memory badPrefix, address implementation) external pure {
        vm.assume(keccak256(badPrefix) != keccak256(ERC1167_PREFIX));
        bytes memory bytecode = abi.encodePacked(badPrefix, implementation, ERC1167_SUFFIX);
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(!result);
        assertEq(implementationResult, address(0));
    }

    /// ERC1167 has known prefix so any other 10-byte prefix is not a proxy.
    /// Constrains badPrefix to exactly 10 bytes so the hash comparison path is
    /// exercised rather than the length-check early return.
    function testIsERC1167ProxyPrefixFail45Bytes(bytes10 badPrefix, address implementation) external pure {
        vm.assume(keccak256(abi.encodePacked(badPrefix)) != keccak256(ERC1167_PREFIX));
        bytes memory bytecode = abi.encodePacked(badPrefix, implementation, ERC1167_SUFFIX);
        assertEq(bytecode.length, ERC1167_PROXY_LENGTH);
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(!result);
        assertEq(implementationResult, address(0));
    }

    /// ERC1167 has known suffix so any other suffix is not a proxy.
    /// Does NOT constrain length -- tests the length-check early return.
    function testIsERC1167ProxySuffixFail(bytes memory badSuffix, address implementation) external pure {
        vm.assume(keccak256(badSuffix) != keccak256(ERC1167_SUFFIX));
        bytes memory bytecode = abi.encodePacked(ERC1167_PREFIX, implementation, badSuffix);
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(!result);
        assertEq(implementationResult, address(0));
    }

    /// ERC1167 has known suffix so any other 15-byte suffix is not a proxy.
    /// Constrains badSuffix to exactly 15 bytes so the hash comparison path is
    /// exercised rather than the length-check early return.
    function testIsERC1167ProxySuffixFail45Bytes(bytes15 badSuffix, address implementation) external pure {
        vm.assume(keccak256(abi.encodePacked(badSuffix)) != keccak256(ERC1167_SUFFIX));
        bytes memory bytecode = abi.encodePacked(ERC1167_PREFIX, implementation, badSuffix);
        assertEq(bytecode.length, ERC1167_PROXY_LENGTH);
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(!result);
        assertEq(implementationResult, address(0));
    }

    /// Test 45-byte bytecode where both prefix and suffix are wrong.
    function testIsERC1167ProxyBothPrefixAndSuffixFail(bytes10 badPrefix, address implementation, bytes15 badSuffix)
        external
        pure
    {
        vm.assume(keccak256(abi.encodePacked(badPrefix)) != keccak256(ERC1167_PREFIX));
        vm.assume(keccak256(abi.encodePacked(badSuffix)) != keccak256(ERC1167_SUFFIX));
        bytes memory bytecode = abi.encodePacked(badPrefix, implementation, badSuffix);
        assertEq(bytecode.length, ERC1167_PROXY_LENGTH);
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(!result);
        assertEq(implementationResult, address(0));
    }

    /// The correct implementation of ERC1167 is detected as a proxy and the
    /// implementation address is returned.
    function testIsERC1167ProxySuccess(address implementation) external pure {
        bytes memory bytecode = abi.encodePacked(ERC1167_PREFIX, implementation, ERC1167_SUFFIX);
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(result);
        assertEq(implementationResult, implementation);
    }

    /// Compare the fail case of the slow implementation to the fast.
    function testIsERC1167ProxySlowFail(bytes memory bytecode) external pure {
        (bool result, address implementationResult) = LibExtrospectionSlow.isERC1167ProxySlow(bytecode);
        (bool resultFast, address implementationResultFast) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        vm.assume(!result);
        assertEq(result, resultFast);
        assertEq(implementationResult, implementationResultFast);
    }

    /// Compare the success case of the slow implementation to the fast.
    function testIsERC1167ProxySlowSuccess(address implementation) external pure {
        bytes memory bytecode = abi.encodePacked(ERC1167_PREFIX, implementation, ERC1167_SUFFIX);
        (bool result, address implementationResult) = LibExtrospectionSlow.isERC1167ProxySlow(bytecode);
        (bool resultFast, address implementationResultFast) = LibExtrospectERC1167Proxy.isERC1167Proxy(bytecode);
        assertTrue(result);
        assertEq(result, resultFast);
        assertEq(implementationResult, implementationResultFast);
    }

    /// Gas cost of the fast implementation failing on length.
    function testIsERC1167ProxyGasFailLength() external pure {
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy("");
        (result);
        (implementationResult);
    }

    /// Gas cost of the fast implementation failing on prefix.
    function testIsERC1167ProxyGasFailPrefix() external pure {
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(
            // 45 bytes
            hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        );
        (result);
        (implementationResult);
    }

    /// Gas cost of the fast implementation failing on suffix.
    function testIsERC1167ProxyGasFailSuffix() external pure {
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(
            hex"363d3d373d3d3d363d730000000000000000000000000000000000000000000000000000000000000000000000"
        );
        (result);
        (implementationResult);
    }

    /// Validate ERC-1167 constants against the specification.
    /// https://eips.ethereum.org/EIPS/eip-1167
    function testERC1167Constants() external pure {
        assertEq(ERC1167_PREFIX, hex"363d3d373d3d3d363d73");
        assertEq(ERC1167_SUFFIX, hex"5af43d82803e903d91602b57fd5bf3");
        assertEq(ERC1167_PREFIX_LENGTH, 10);
        assertEq(ERC1167_SUFFIX_LENGTH, 15);
        assertEq(ERC1167_PROXY_LENGTH, 45);
    }

    /// Gas cost of the fast implementation succeeding.
    function testIsERC1167ProxyGasSuccess() external pure {
        (bool result, address implementationResult) = LibExtrospectERC1167Proxy.isERC1167Proxy(
            hex"363d3d373d3d3d363d7300000000000000000000000000000000000000005af43d82803e903d91602b57fd5bf3"
        );
        (result);
        (implementationResult);
    }
}
