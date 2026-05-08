// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract ExtrospectScanEVMOpcodesPresentInBytecodeTest is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }

    function testScanEVMOpcodesPresentInBytecodeEquivalenceFuzz(bytes memory bytecode) external {
        try this._extScan(bytecode) returns (uint256 ext) {
            uint256 lib = LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(bytecode);
            assertEq(ext, lib);
        } catch {
            vm.expectRevert();
            this._libScan(bytecode);
        }
    }

    function _extScan(bytes memory bytecode) external view returns (uint256) {
        return extrospect.scanEVMOpcodesPresentInBytecode(bytecode);
    }

    function _libScan(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(bytecode);
    }

    function testScanEVMOpcodesPresentInBytecodeEquivalenceConcrete() external view {
        bytes memory code = hex"60016002F3";
        assertEq(
            extrospect.scanEVMOpcodesPresentInBytecode(code),
            LibExtrospectBytecode.scanEVMOpcodesPresentInBytecode(code)
        );
    }
}
