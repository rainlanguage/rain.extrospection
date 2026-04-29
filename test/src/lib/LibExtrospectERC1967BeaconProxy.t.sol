// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {
    LibExtrospectERC1967BeaconProxy,
    ERC1967_IMPLEMENTATION_SLOT,
    ERC1967_ADMIN_SLOT,
    ERC1967_BEACON_SLOT,
    SOLADY_ERC1967_BEACON_PROXY_RUNTIME_HASH,
    SOLADY_ERC1967I_BEACON_PROXY_RUNTIME_HASH
} from "src/lib/LibExtrospectERC1967BeaconProxy.sol";

/// @title LibExtrospectERC1967BeaconProxyTest
/// @notice Tests the slot constants and Solady-template detection.
contract LibExtrospectERC1967BeaconProxyTest is Test {
    /// `ERC1967_IMPLEMENTATION_SLOT` matches the EIP-1967 derivation
    /// `keccak256("eip1967.proxy.implementation") - 1`.
    function testImplementationSlotMatchesDerivation() external pure {
        assertEq(ERC1967_IMPLEMENTATION_SLOT, bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    }

    /// `ERC1967_ADMIN_SLOT` matches the EIP-1967 derivation
    /// `keccak256("eip1967.proxy.admin") - 1`.
    function testAdminSlotMatchesDerivation() external pure {
        assertEq(ERC1967_ADMIN_SLOT, bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
    }

    /// `ERC1967_BEACON_SLOT` matches the EIP-1967 derivation
    /// `keccak256("eip1967.proxy.beacon") - 1`.
    function testBeaconSlotMatchesDerivation() external pure {
        assertEq(ERC1967_BEACON_SLOT, bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
    }

    /// The three EIP-1967 slots are pairwise distinct.
    function testSlotsAreDistinct() external pure {
        assertTrue(ERC1967_IMPLEMENTATION_SLOT != ERC1967_ADMIN_SLOT);
        assertTrue(ERC1967_IMPLEMENTATION_SLOT != ERC1967_BEACON_SLOT);
        assertTrue(ERC1967_ADMIN_SLOT != ERC1967_BEACON_SLOT);
    }

    /// The two Solady runtime hashes are distinct (the minimal and
    /// ERC1967I variants are different bytecode).
    function testSoladyRuntimeHashesAreDistinct() external pure {
        assertTrue(SOLADY_ERC1967_BEACON_PROXY_RUNTIME_HASH != SOLADY_ERC1967I_BEACON_PROXY_RUNTIME_HASH);
    }

    /// Arbitrary bytecode whose hash differs from the Solady minimal
    /// template hash is not detected as a Solady minimal beacon proxy.
    function testFuzzNonMatchingBytecodeIsNotSoladyMinimal(bytes memory bytecode) external pure {
        vm.assume(keccak256(bytecode) != SOLADY_ERC1967_BEACON_PROXY_RUNTIME_HASH);
        assertFalse(LibExtrospectERC1967BeaconProxy.isSoladyERC1967BeaconProxy(bytecode));
    }

    /// Arbitrary bytecode whose hash differs from the Solady ERC1967I
    /// template hash is not detected as a Solady ERC1967I beacon proxy.
    function testFuzzNonMatchingBytecodeIsNotSoladyERC1967I(bytes memory bytecode) external pure {
        vm.assume(keccak256(bytecode) != SOLADY_ERC1967I_BEACON_PROXY_RUNTIME_HASH);
        assertFalse(LibExtrospectERC1967BeaconProxy.isSoladyERC1967IBeaconProxy(bytecode));
    }

    /// `isAnySoladyERC1967BeaconProxy` returns false on bytecode that
    /// matches neither template.
    function testFuzzNonMatchingBytecodeIsNotAnySolady(bytes memory bytecode) external pure {
        vm.assume(keccak256(bytecode) != SOLADY_ERC1967_BEACON_PROXY_RUNTIME_HASH);
        vm.assume(keccak256(bytecode) != SOLADY_ERC1967I_BEACON_PROXY_RUNTIME_HASH);
        assertFalse(LibExtrospectERC1967BeaconProxy.isAnySoladyERC1967BeaconProxy(bytecode));
    }

    /// Empty bytecode is not detected as any beacon proxy template.
    function testEmptyBytecodeIsNotABeaconProxy() external pure {
        bytes memory empty = "";
        assertFalse(LibExtrospectERC1967BeaconProxy.isSoladyERC1967BeaconProxy(empty));
        assertFalse(LibExtrospectERC1967BeaconProxy.isSoladyERC1967IBeaconProxy(empty));
        assertFalse(LibExtrospectERC1967BeaconProxy.isAnySoladyERC1967BeaconProxy(empty));
    }
}
