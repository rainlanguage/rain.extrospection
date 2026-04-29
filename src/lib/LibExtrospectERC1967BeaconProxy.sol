// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @dev EIP-1967 implementation storage slot.
/// `bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)`.
bytes32 constant ERC1967_IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

/// @dev EIP-1967 admin storage slot.
/// `bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)`.
bytes32 constant ERC1967_ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

/// @dev EIP-1967 beacon storage slot.
/// `bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1)`.
bytes32 constant ERC1967_BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

/// @dev `keccak256` of the runtime bytecode of Solady's minimal ERC-1967
/// beacon proxy. Sourced from `solady/src/utils/LibClone.sol`
/// (`ERC1967_BEACON_PROXY_CODE_HASH`). The proxy's runtime is fixed —
/// the beacon address lives in the proxy's `ERC1967_BEACON_SLOT`, not in
/// bytecode — so every Solady-deployed minimal beacon proxy has the same
/// runtime hash regardless of which beacon it points at.
bytes32 constant SOLADY_ERC1967_BEACON_PROXY_RUNTIME_HASH =
    0x14044459af17bc4f0f5aa2f658cb692add77d1302c29fe2aebab005eea9d1162;

/// @dev `keccak256` of the runtime bytecode of Solady's ERC1967I beacon
/// proxy variant (with the `calldatasize() == 1` short-circuit that
/// returns `implementation()` directly). Sourced from
/// `solady/src/utils/LibClone.sol` (`ERC1967I_BEACON_PROXY_CODE_HASH`).
bytes32 constant SOLADY_ERC1967I_BEACON_PROXY_RUNTIME_HASH =
    0xf8c46d2793d5aa984eb827aeaba4b63aedcab80119212fce827309788735519a;

/// @title LibExtrospectERC1967BeaconProxy
/// @notice Bytecode-level detection of ERC-1967 beacon proxies, plus the
/// canonical EIP-1967 storage slot constants for callers that need to
/// read proxy slot state directly.
///
/// Unlike ERC-1167 minimal proxies, an ERC-1967 beacon proxy's beacon
/// address is held in storage, not in bytecode. Two practical
/// consequences:
///
/// 1. The runtime bytecode is fixed for any given beacon-proxy
///    implementation (Solady's minimal, Solady's ERC1967I variant, OZ's
///    `BeaconProxy`, etc.) — a single hash uniquely identifies "this is
///    a Solady minimal beacon proxy" regardless of which beacon it
///    points at.
/// 2. The beacon address itself cannot be extracted from bytecode. To
///    read it you need either storage access to the proxy
///    (`SLOAD(ERC1967_BEACON_SLOT)`, only available from delegatecall
///    context or via an off-chain `eth_getStorageAt` / Foundry's
///    `vm.load`) or a proxy that exposes a non-standard public getter.
///
/// This library covers what's possible from bytecode alone — detection
/// of known beacon-proxy templates — and exports the slot constants so
/// any caller that has slot-reading access elsewhere can use a single
/// canonical source for the slot addresses.
library LibExtrospectERC1967BeaconProxy {
    /// @notice Checks if `bytecode` is the runtime bytecode of Solady's
    /// minimal ERC-1967 beacon proxy.
    /// @param bytecode The runtime bytecode to check (e.g. obtained via
    /// `address.code` or `extcodecopy`).
    /// @return True if the bytecode hash matches Solady's minimal beacon
    /// proxy template.
    function isSoladyERC1967BeaconProxy(bytes memory bytecode) internal pure returns (bool) {
        return keccak256(bytecode) == SOLADY_ERC1967_BEACON_PROXY_RUNTIME_HASH;
    }

    /// @notice Checks if `bytecode` is the runtime bytecode of Solady's
    /// ERC1967I beacon proxy variant.
    /// @param bytecode The runtime bytecode to check.
    /// @return True if the bytecode hash matches Solady's ERC1967I beacon
    /// proxy template.
    function isSoladyERC1967IBeaconProxy(bytes memory bytecode) internal pure returns (bool) {
        return keccak256(bytecode) == SOLADY_ERC1967I_BEACON_PROXY_RUNTIME_HASH;
    }

    /// @notice Checks if `bytecode` is any of the known Solady ERC-1967
    /// beacon proxy templates.
    /// @param bytecode The runtime bytecode to check.
    /// @return True if the bytecode hash matches either the minimal or
    /// the ERC1967I beacon proxy template.
    function isAnySoladyERC1967BeaconProxy(bytes memory bytecode) internal pure returns (bool) {
        bytes32 h = keccak256(bytecode);
        return h == SOLADY_ERC1967_BEACON_PROXY_RUNTIME_HASH || h == SOLADY_ERC1967I_BEACON_PROXY_RUNTIME_HASH;
    }
}
