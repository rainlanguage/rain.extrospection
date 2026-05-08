// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
import {SOLIDITY_CBOR_RUNTIME_FIXTURE} from "test/concrete/SolidityCBORFixture.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract ExtrospectCheckNoSolidityCBORMetadataTest is ExtrospectEquivalence {
    function libCheckNoSolidityCBORMetadataExternal(address account) external view {
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(account);
    }

    function testCheckNoSolidityCBORMetadataEquivalencePass() external view {
        // Account with no code passes both.
        extrospect.checkNoSolidityCBORMetadata(address(0xdead));
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(address(0xdead));
    }

    function testCheckNoSolidityCBORMetadataEquivalenceRevert() external {
        bytes memory withMeta = SOLIDITY_CBOR_RUNTIME_FIXTURE;
        address deployed = address(0xbeef);
        vm.etch(deployed, withMeta);

        vm.expectRevert(LibExtrospectBytecode.UnexpectedMetadata.selector);
        extrospect.checkNoSolidityCBORMetadata(deployed);
        vm.expectRevert(LibExtrospectBytecode.UnexpectedMetadata.selector);
        this.libCheckNoSolidityCBORMetadataExternal(deployed);
    }
}
