// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";

import {LibExtrospectEmbeddedAddress} from "src/lib/LibExtrospectEmbeddedAddress.sol";
import {LibExtrospectionSlow} from "test/lib/LibExtrospectionSlow.sol";

/// @title LibExtrospectEmbeddedAddressContainsAddressTest
/// @notice The oracle is `LibExtrospectionSlow.containsAddressSlow`, a byte by
/// byte search for the address with its leading zero bytes dropped.
contract LibExtrospectEmbeddedAddressContainsAddressTest is Test {
    bytes1 constant FILLER = 0xee;

    function filler(uint256 length) internal pure returns (bytes memory bytes_) {
        bytes_ = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            bytes_[i] = FILLER;
        }
    }

    function truncate(bytes memory bytes_, uint256 length) internal pure {
        assembly ("memory-safe") {
            mstore(bytes_, length)
        }
    }

    /// For each width 1..20 an address whose bytes are 0x01.., none equal to
    /// the filler, at every offset across two word boundaries, at the end and
    /// with a word of filler after it. Absent with its last byte changed, and
    /// cut one byte short while that byte stays in memory past the end.
    function testAddressAtEveryOffset() external pure {
        for (uint256 width = 1; width <= 20; width++) {
            bytes memory stripped = new bytes(width);
            uint160 value = 0;
            for (uint8 k = 0; k < width; k++) {
                stripped[k] = bytes1(k + 1);
                value = (value << 8) | uint160(k + 1);
            }
            address needle = address(value);
            assertEq(LibExtrospectionSlow.strippedAddressSlow(needle), stripped);
            bytes memory changed = bytes.concat(stripped);
            changed[width - 1] = FILLER;
            for (uint256 offset = 0; offset <= 96; offset++) {
                bytes memory atEnd = bytes.concat(filler(offset), stripped);
                assertTrue(LibExtrospectEmbeddedAddress.containsAddress(atEnd, needle));
                assertTrue(LibExtrospectEmbeddedAddress.containsAddress(bytes.concat(atEnd, filler(33)), needle));
                assertFalse(
                    LibExtrospectEmbeddedAddress.containsAddress(
                        bytes.concat(filler(offset), changed, filler(33)), needle
                    )
                );
                truncate(atEnd, atEnd.length - 1);
                assertFalse(LibExtrospectEmbeddedAddress.containsAddress(atEnd, needle));
            }
        }
    }

    function testAddressAtAnyOffset(bytes memory prefix, address needle, bytes memory suffix) external pure {
        vm.assume(needle != address(0));
        bytes memory haystack = bytes.concat(prefix, LibExtrospectionSlow.strippedAddressSlow(needle), suffix);
        assertTrue(LibExtrospectEmbeddedAddress.containsAddress(haystack, needle));
    }

    function testHaystackIsExactlyTheAddress(address needle) external pure {
        vm.assume(needle != address(0));
        bytes memory stripped = LibExtrospectionSlow.strippedAddressSlow(needle);
        assertTrue(LibExtrospectEmbeddedAddress.containsAddress(stripped, needle));
    }

    /// The cut byte stays in memory past the end.
    function testHaystackShorterThanTheAddressIsNot(address needle, uint256 cut) external pure {
        vm.assume(needle != address(0));
        bytes memory stripped = LibExtrospectionSlow.strippedAddressSlow(needle);
        cut = bound(cut, 1, stripped.length);
        truncate(stripped, stripped.length - cut);
        assertFalse(LibExtrospectEmbeddedAddress.containsAddress(stripped, needle));
    }

    function testZeroAddressIsNeverContained(bytes memory haystack) external pure {
        assertFalse(LibExtrospectEmbeddedAddress.containsAddress(haystack, address(0)));
        assertFalse(LibExtrospectEmbeddedAddress.containsAddress("", address(0)));
        assertFalse(LibExtrospectEmbeddedAddress.containsAddress(new bytes(64), address(0)));
    }

    function testAddressWithLeadingZeroBytes() external pure {
        address needle = address(uint160(0xc0ffee5eed));
        assertTrue(LibExtrospectEmbeddedAddress.containsAddress(abi.encode(needle), needle));
        assertTrue(LibExtrospectEmbeddedAddress.containsAddress(hex"64c0ffee5eed3f", needle));
        assertFalse(LibExtrospectEmbeddedAddress.containsAddress(hex"64c0ffee5e3f", needle));
        assertFalse(LibExtrospectEmbeddedAddress.containsAddress(hex"64ffee5eed3f", needle));
    }

    function testFullWidthAddress() external pure {
        address needle = address(type(uint160).max);
        bytes memory haystack = new bytes(20);
        for (uint256 i = 0; i < 20; i++) {
            haystack[i] = 0xff;
        }
        assertTrue(LibExtrospectEmbeddedAddress.containsAddress(haystack, needle));
        haystack[19] = 0xfe;
        assertFalse(LibExtrospectEmbeddedAddress.containsAddress(haystack, needle));
    }

    function testMatchesReference(bytes memory haystack, address needle) external pure {
        assertEq(
            LibExtrospectEmbeddedAddress.containsAddress(haystack, needle),
            LibExtrospectionSlow.containsAddressSlow(haystack, needle)
        );
    }

    /// The needle is a window of the haystack, so may have leading zero
    /// bytes, and one haystack byte may then change.
    function testMatchesReferenceForAWindow(
        bytes memory haystack,
        uint256 offset,
        uint256 width,
        uint256 index,
        uint8 flip
    ) external pure {
        vm.assume(haystack.length != 0);
        width = bound(width, 1, haystack.length < 20 ? haystack.length : 20);
        offset = bound(offset, 0, haystack.length - width);
        uint160 value = 0;
        for (uint256 k = 0; k < width; k++) {
            value = (value << 8) | uint160(uint8(haystack[offset + k]));
        }
        address needle = address(value);
        index = bound(index, 0, haystack.length - 1);
        haystack[index] ^= bytes1(flip);
        assertEq(
            LibExtrospectEmbeddedAddress.containsAddress(haystack, needle),
            LibExtrospectionSlow.containsAddressSlow(haystack, needle)
        );
    }
}
