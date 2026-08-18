// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IBeacon} from "src/interface/IBeacon.sol";
import {IOwnable} from "src/interface/IOwnable.sol";

/// @dev The implementation address a `StrictCalldataBeacon` reports. It
/// has no code, so its runtime bytecode hashes to `keccak256("")`.
address constant STRICT_CALLDATA_BEACON_IMPLEMENTATION = address(uint160(0x5721C7));

/// @dev The owner address a `StrictCalldataBeacon` reports.
address constant STRICT_CALLDATA_BEACON_OWNER = address(uint160(0x0FFE6));

/// @dev Beacon test fixture whose `implementation()` and `owner()`
/// revert unless the calldata is exactly the 4 selector bytes and
/// nothing else. Pins the calldata `_tryGetAddress` sends: a bare
/// selector, with no padding after it.
contract StrictCalldataBeacon is IBeacon, IOwnable {
    function implementation() external pure returns (address) {
        _requireBareSelector();
        return STRICT_CALLDATA_BEACON_IMPLEMENTATION;
    }

    function owner() external pure returns (address) {
        _requireBareSelector();
        return STRICT_CALLDATA_BEACON_OWNER;
    }

    /// @dev Reverts on any calldata longer or shorter than the 4
    /// selector bytes.
    function _requireBareSelector() internal pure {
        require(msg.data.length == 4, "calldata is not a bare selector");
    }
}
