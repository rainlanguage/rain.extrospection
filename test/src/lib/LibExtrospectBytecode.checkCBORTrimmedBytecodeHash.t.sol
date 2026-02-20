// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectTestProd} from "test/lib/LibExtrospectTestProd.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract LibExtrospectBytecodeCheckCBORTrimmedBytecodeHashTest is Test {
    address constant PROD_ARBITRUM_CLONE_FACTORY_ADDRESS_V1 = address(0xe01Db32B1E03976b24e3A948A560f4b97Dd732dA);
    bytes32 constant PROD_ARBITRUM_CLONE_FACTORY_CODEHASH_V1 =
        bytes32(0x7b085ca3e5c659da29caf26d23e7b72fd4fdbc59aa6b5611cf3918c4586ec73a);

    function externalCheckCBORTrimmedBytecodeHash(address target, bytes32 expectedCodeHash) external view {
        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(target, expectedCodeHash);
    }

    function testCheckCBORTrimmedBytecodeHashSuccess() external {
        LibExtrospectTestProd.createSelectForkArbitrum(vm);

        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(
            PROD_ARBITRUM_CLONE_FACTORY_ADDRESS_V1, PROD_ARBITRUM_CLONE_FACTORY_CODEHASH_V1
        );
    }

    function testCheckCBORTrimmedBytecodeHashFailure() external {
        bytes32 expectedCodeHash = bytes32(0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF);
        LibExtrospectTestProd.createSelectForkArbitrum(vm);

        bytes32 actualCodeHash = PROD_ARBITRUM_CLONE_FACTORY_CODEHASH_V1;

        vm.expectRevert(
            abi.encodeWithSelector(
                LibExtrospectBytecode.BytecodeHashMismatch.selector, expectedCodeHash, actualCodeHash
            )
        );
        this.externalCheckCBORTrimmedBytecodeHash(PROD_ARBITRUM_CLONE_FACTORY_ADDRESS_V1, expectedCodeHash);
    }

    /// Test that an empty account (no deployed code) reverts with
    /// MetadataNotTrimmed since there is no metadata to trim.
    function testCheckCBORTrimmedBytecodeHashEmptyAccount() external {
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.MetadataNotTrimmed.selector));
        this.externalCheckCBORTrimmedBytecodeHash(address(0xdead), bytes32(0));
    }

    function testCheckCBORTrimmedBytecodeHashMetadataNotTrimmed() external {
        bytes32 expectedCodeHash = bytes32(0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF);
        LibExtrospectTestProd.createSelectForkArbitrum(vm);

        // Use an account that does not have Solidity CBOR metadata and is
        // therefore not trimmed.
        // This is a deployed rain interpreter contract.
        address accountWithoutMetadata = address(0x1Bd4F25881B5A82302Edc07FCa994faa21baec7F);

        // The code hash does not matter because the error for trimming happens
        // before the hash is checked.
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.MetadataNotTrimmed.selector));
        this.externalCheckCBORTrimmedBytecodeHash(accountWithoutMetadata, expectedCodeHash);
    }
}
