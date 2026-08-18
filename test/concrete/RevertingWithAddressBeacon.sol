// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

/// @dev The address every `RevertingWithAddressBeacon` puts in its
/// revert data. It has no code, so its runtime bytecode hashes to
/// `keccak256("")`.
address constant REVERTING_WITH_ADDRESS_BEACON_PAYLOAD = address(uint160(0x1234));

/// @dev Beacon test fixture whose `implementation()` and `owner()`
/// revert with exactly 32 bytes of revert data that decode cleanly as
/// an address. A failed call still leaves `returndata` populated, so
/// the length check and the dirty-bits check both pass on it: only the
/// `success` flag distinguishes this from a successful call. Pins that
/// `_tryGetAddress` reads the staticcall's success flag rather than
/// inferring failure from the shape of the returned bytes.
contract RevertingWithAddressBeacon {
    function implementation() external pure returns (address) {
        _revertWithAddress();
    }

    function owner() external pure returns (address) {
        _revertWithAddress();
    }

    /// @dev Reverts with the 32-byte word holding
    /// `REVERTING_WITH_ADDRESS_BEACON_PAYLOAD`, right-aligned and with
    /// zero upper bits — byte-identical to a successful `address`
    /// return.
    function _revertWithAddress() internal pure {
        address payload = REVERTING_WITH_ADDRESS_BEACON_PAYLOAD;
        //forge-lint: disable-next-line(assembly-usage)
        assembly ("memory-safe") {
            mstore(0, payload)
            revert(0, 0x20)
        }
    }
}
