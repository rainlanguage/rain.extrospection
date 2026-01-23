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

    function testCheckCBORTrimmedBytecodeHashSuccess() public {
        LibExtrospectTestProd.createSelectForkArbitrum(vm);

        LibExtrospectBytecode.checkCBORTrimmedBytecodeHash(
            PROD_ARBITRUM_CLONE_FACTORY_ADDRESS_V1, PROD_ARBITRUM_CLONE_FACTORY_CODEHASH_V1
        );
    }
}
