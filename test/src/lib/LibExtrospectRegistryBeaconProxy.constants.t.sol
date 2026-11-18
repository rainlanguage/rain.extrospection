// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {LibBytes} from "rain-solmem-0.1.28/src/lib/LibBytes.sol";

import {
    REGISTRY_BEACON_PROXY_PREFIX,
    REGISTRY_BEACON_PROXY_SUFFIX,
    REGISTRY_BEACON_PROXY_PREFIX_WORD_0,
    REGISTRY_BEACON_PROXY_PREFIX_WORD_1,
    REGISTRY_BEACON_PROXY_SUFFIX_WORD_0,
    REGISTRY_BEACON_PROXY_SUFFIX_WORD_1,
    REGISTRY_BEACON_PROXY_SUFFIX_WORD_2,
    REGISTRY_BEACON_PROXY_SUFFIX_WORD_3,
    REGISTRY_BEACON_PROXY_SUFFIX_WORD_4,
    REGISTRY_BEACON_PROXY_SUFFIX_WORD_5,
    REGISTRY_BEACON_PROXY_SUFFIX_WORD_6,
    REGISTRY_BEACON_PROXY_PREFIX_LENGTH,
    REGISTRY_BEACON_PROXY_SUFFIX_LENGTH,
    REGISTRY_BEACON_PROXY_PREFIX_HASH,
    REGISTRY_BEACON_PROXY_SUFFIX_HASH
} from "src/lib/LibExtrospectRegistryBeaconProxy.sol";

contract LibExtrospectRegistryBeaconProxyConstantsTest is Test {
    function prefixWords() internal pure returns (bytes memory) {
        return bytes.concat(REGISTRY_BEACON_PROXY_PREFIX_WORD_0, REGISTRY_BEACON_PROXY_PREFIX_WORD_1);
    }

    function suffixWords() internal pure returns (bytes memory) {
        return bytes.concat(
            REGISTRY_BEACON_PROXY_SUFFIX_WORD_0,
            REGISTRY_BEACON_PROXY_SUFFIX_WORD_1,
            REGISTRY_BEACON_PROXY_SUFFIX_WORD_2,
            REGISTRY_BEACON_PROXY_SUFFIX_WORD_3,
            REGISTRY_BEACON_PROXY_SUFFIX_WORD_4,
            REGISTRY_BEACON_PROXY_SUFFIX_WORD_5,
            REGISTRY_BEACON_PROXY_SUFFIX_WORD_6
        );
    }

    function truncate(bytes memory words, uint256 length) internal pure returns (bytes memory) {
        LibBytes.truncate(words, length);
        return words;
    }

    function assertPaddingIsZero(bytes memory words, uint256 length) internal pure {
        for (uint256 i = length; i < words.length; i++) {
            assertEq(uint8(words[i]), 0);
        }
    }

    /// The prefix and suffix words truncated to their lengths are the prefix and suffix bytes.
    function testTruncatedWordsAreBytes() external pure {
        assertEq(truncate(prefixWords(), REGISTRY_BEACON_PROXY_PREFIX_LENGTH), REGISTRY_BEACON_PROXY_PREFIX);
        assertEq(truncate(suffixWords(), REGISTRY_BEACON_PROXY_SUFFIX_LENGTH), REGISTRY_BEACON_PROXY_SUFFIX);
    }

    /// The prefix and suffix words are zero after their lengths.
    function testWordsPaddingIsZero() external pure {
        assertPaddingIsZero(prefixWords(), REGISTRY_BEACON_PROXY_PREFIX_LENGTH);
        assertPaddingIsZero(suffixWords(), REGISTRY_BEACON_PROXY_SUFFIX_LENGTH);
    }

    /// The prefix and suffix words truncated to their lengths hash to the prefix and suffix hashes.
    function testTruncatedWordsHashToHashes() external pure {
        assertEq(
            keccak256(truncate(prefixWords(), REGISTRY_BEACON_PROXY_PREFIX_LENGTH)), REGISTRY_BEACON_PROXY_PREFIX_HASH
        );
        assertEq(
            keccak256(truncate(suffixWords(), REGISTRY_BEACON_PROXY_SUFFIX_LENGTH)), REGISTRY_BEACON_PROXY_SUFFIX_HASH
        );
    }
}
