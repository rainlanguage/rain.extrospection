// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";

contract ExtrospectScanEVMOpcodesReachableInBytecodeTest is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }

    function testScanEVMOpcodesReachableInBytecodeEquivalenceFuzz(bytes memory bytecode) external {
        // EOF prefix reverts both sides — skip via try/catch comparison.
        try this._extScan(bytecode) returns (uint256 ext) {
            uint256 lib = LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode);
            assertEq(ext, lib);
        } catch {
            // Library should also revert.
            vm.expectRevert();
            this._libScan(bytecode);
        }
    }

    function _extScan(bytes memory bytecode) external view returns (uint256) {
        return extrospect.scanEVMOpcodesReachableInBytecode(bytecode);
    }

    function _libScan(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode);
    }

    function testScanEVMOpcodesReachableInBytecodeEquivalenceConcrete() external view {
        bytes memory code = hex"60016002F3"; // PUSH1 0x01 PUSH1 0x02 RETURN
        assertEq(
            extrospect.scanEVMOpcodesReachableInBytecode(code),
            LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(code)
        );
    }
}
