// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {CleanContract} from "test/concrete/CleanContract.sol";

contract LibExtrospectBytecodeCheckNoSolidityCBORMetadataTest is Test {
    /// External wrapper for revert tests.
    //forge-lint: disable-next-line(mixed-case-function)
    function checkNoSolidityCBORMetadataExternal(address account) external view {
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(account);
    }

    /// Account with no code passes (no metadata to detect).
    function testCheckNoMetadataEmptyAccount() external view {
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(address(0xdead));
    }

    /// Contract compiled without metadata passes. This project compiles with
    /// cbor_metadata = false so all contracts deployed in tests lack metadata.
    function testCheckNoMetadataCleanContract() external {
        CleanContract clean = new CleanContract();
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(address(clean));
    }

    /// Bytecode with standard CBOR metadata reverts.
    function testCheckNoMetadataRevertsOnMetadata() external {
        // Runtime bytecode with standard Solidity CBOR metadata appended.
        // We use vm.etch since the project itself compiles without metadata.
        bytes memory runtimeCode =
            hex"6080604052600080fdfea26469706673582212200726074213b9ef2f5b41bf0bdd5bbd03a64652de62f1dfcda59625e106c52e8a64736f6c63430008190033";
        address deployed = address(0xbeef);
        vm.etch(deployed, runtimeCode);
        vm.expectRevert(LibExtrospectBytecode.UnexpectedMetadata.selector);
        this.checkNoSolidityCBORMetadataExternal(deployed);
    }
}
