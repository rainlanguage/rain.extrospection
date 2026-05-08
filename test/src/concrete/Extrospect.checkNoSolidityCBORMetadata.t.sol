// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ExtrospectEquivalence} from "test/concrete/ExtrospectEquivalence.sol";
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
        bytes memory withMeta =
            hex"6080604052600080fdfea26469706673582212200726074213b9ef2f5b41bf0bdd5bbd03a64652de62f1dfcda59625e106c52e8a64736f6c63430008190033";
        address deployed = address(0xbeef);
        vm.etch(deployed, withMeta);

        vm.expectRevert(LibExtrospectBytecode.UnexpectedMetadata.selector);
        extrospect.checkNoSolidityCBORMetadata(deployed);
        vm.expectRevert(LibExtrospectBytecode.UnexpectedMetadata.selector);
        this.libCheckNoSolidityCBORMetadataExternal(deployed);
    }
}
