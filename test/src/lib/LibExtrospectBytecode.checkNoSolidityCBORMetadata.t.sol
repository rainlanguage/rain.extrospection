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

    /// EOF bytecode etched onto an account reverts with EOFBytecodeNotSupported.
    function testCheckNoMetadataEOF() external {
        address target = address(0xBEEF);
        vm.etch(target, hex"EF00010203");
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.checkNoSolidityCBORMetadataExternal(target);
    }

    /// Fuzz: bytecode without valid metadata passes.
    function testCheckNoMetadataPassesFuzz(bytes memory code) external {
        vm.assume(code.length > 0);
        vm.assume(!LibExtrospectBytecode.isEOFBytecode(code));
        vm.assume(!LibExtrospectBytecode.tryTrimSolidityCBORMetadata(code));

        address target = address(0xBEEF);
        vm.etch(target, code);
        LibExtrospectBytecode.checkNoSolidityCBORMetadata(target);
    }

    /// Fuzz: bytecode with valid CBOR metadata appended reverts.
    function testCheckNoMetadataRevertsFuzz(bytes memory code) external {
        vm.assume(!LibExtrospectBytecode.isEOFBytecode(code));

        // Build synthetic IPFS hash and solc version from fuzz input.
        bytes32 seed = keccak256(code);
        bytes memory ipfsHash = new bytes(34);
        assembly ("memory-safe") {
            mstore(add(ipfsHash, 0x20), seed)
            mstore(add(ipfsHash, 0x40), keccak256(0, 0x20))
        }
        bytes memory solcVersion = new bytes(3);
        assembly ("memory-safe") {
            mstore(add(solcVersion, 0x20), seed)
        }

        bytes memory withMetadata =
            bytes.concat(code, hex"a264697066735822", ipfsHash, hex"64736f6c6343", solcVersion, hex"0033");

        address target = address(0xBEEF);
        vm.etch(target, withMetadata);
        vm.expectRevert(LibExtrospectBytecode.UnexpectedMetadata.selector);
        this.checkNoSolidityCBORMetadataExternal(target);
    }
}
