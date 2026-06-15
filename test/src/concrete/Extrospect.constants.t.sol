// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {
    Extrospect,
    EXTROSPECT_ZOLTU_ADDRESS_V1,
    EXTROSPECT_RUNTIME_CODEHASH_V1,
    EXTROSPECT_CREATION_BYTECODE_V1
} from "src/concrete/Extrospect.sol";
import {LibRainDeploy} from "rain-deploy-0.1.3/src/lib/LibRainDeploy.sol";

/// @title ExtrospectConstantsTest
/// @notice Pin the Extrospect deploy constants — creation bytecode,
/// deterministic Zoltu address, runtime codehash — so the deploy script
/// and downstream consumers can rely on them as source of truth. If any
/// fails the constant must be updated to match the current source.
contract ExtrospectConstantsTest is Test {
    /// `EXTROSPECT_CREATION_BYTECODE_V1` matches the current compiler
    /// output. Compiler/optimizer settings affect creation bytecode, so
    /// any drift here forces an explicit constant update before the
    /// downstream pins (address + runtime hash) can hold.
    function testExtrospectCreationBytecode() external pure {
        assertEq(
            keccak256(EXTROSPECT_CREATION_BYTECODE_V1),
            keccak256(type(Extrospect).creationCode),
            "EXTROSPECT_CREATION_BYTECODE_V1 drifted from compiler output"
        );
    }

    /// Deterministic CREATE2 address derived from the pinned creation
    /// bytecode plus Zoltu factory + salt(0). Pinned in source so the
    /// deploy script doesn't need an out-of-band env var.
    function testExtrospectZoltuAddress() external pure {
        address actual = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            LibRainDeploy.ZOLTU_FACTORY,
                            bytes32(0),
                            keccak256(EXTROSPECT_CREATION_BYTECODE_V1)
                        )
                    )
                )
            )
        );
        assertEq(actual, EXTROSPECT_ZOLTU_ADDRESS_V1, "EXTROSPECT_ZOLTU_ADDRESS_V1 drifted from creation bytecode");
    }

    /// Runtime codehash pinned for post-deploy verification.
    function testExtrospectRuntimeCodehash() external pure {
        bytes32 actual = keccak256(type(Extrospect).runtimeCode);
        assertEq(actual, EXTROSPECT_RUNTIME_CODEHASH_V1, "EXTROSPECT_RUNTIME_CODEHASH_V1 drifted from runtime bytecode");
    }
}
