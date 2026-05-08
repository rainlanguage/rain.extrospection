// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";
import {LibExtrospectMetamorphic} from "src/lib/LibExtrospectMetamorphic.sol";

contract ExtrospectScanMetamorphicRiskTest is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }

    function testScanMetamorphicRiskEquivalenceFuzz(bytes memory bytecode) external {
        try this._extScan(bytecode) returns (uint256 ext) {
            uint256 lib = LibExtrospectMetamorphic.scanMetamorphicRisk(bytecode);
            assertEq(ext, lib);
        } catch {
            vm.expectRevert();
            this._libScan(bytecode);
        }
    }

    function _extScan(bytes memory bytecode) external view returns (uint256) {
        return extrospect.scanMetamorphicRisk(bytecode);
    }

    function _libScan(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectMetamorphic.scanMetamorphicRisk(bytecode);
    }

    function testScanMetamorphicRiskEquivalenceWithDelegatecall() external view {
        bytes memory code = hex"60006000600060006000F4";
        assertEq(extrospect.scanMetamorphicRisk(code), LibExtrospectMetamorphic.scanMetamorphicRisk(code));
    }
}
