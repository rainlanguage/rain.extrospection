// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
import {SOLIDITY_CBOR_RUNTIME_FIXTURE} from "test/concrete/SolidityCBORFixture.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract ExtrospectTryTrimSolidityCBORMetadataTest is ExtrospectEquivalence {
    function testTryTrimSolidityCBORMetadataEquivalenceTrim() external view {
        bytes memory raw = SOLIDITY_CBOR_RUNTIME_FIXTURE;

        // Library version (mutates in place — clone first).
        bytes memory libCopy = bytes.concat(raw);
        bool libDidTrim = LibExtrospectBytecode.tryTrimSolidityCBORMetadata(libCopy);

        // Extrospect version returns the (possibly trimmed) bytes.
        (bool extDidTrim, bytes memory extResult) = extrospect.tryTrimSolidityCBORMetadata(raw);

        assertEq(libDidTrim, extDidTrim, "didTrim mismatch");
        assertEq(keccak256(libCopy), keccak256(extResult), "trimmed result mismatch");
    }

    function testTryTrimSolidityCBORMetadataEquivalenceNoTrim() external view {
        bytes memory clean = hex"6080604052600080fd";

        bytes memory libCopy = bytes.concat(clean);
        bool libDidTrim = LibExtrospectBytecode.tryTrimSolidityCBORMetadata(libCopy);
        (bool extDidTrim, bytes memory extResult) = extrospect.tryTrimSolidityCBORMetadata(clean);

        assertEq(libDidTrim, extDidTrim);
        assertEq(keccak256(libCopy), keccak256(extResult));
    }
}
