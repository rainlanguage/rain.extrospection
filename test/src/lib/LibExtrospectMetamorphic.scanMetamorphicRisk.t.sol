// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibExtrospectMetamorphic} from "src/lib/LibExtrospectMetamorphic.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {
    EVM_OP_SELFDESTRUCT,
    EVM_OP_DELEGATECALL,
    EVM_OP_CALLCODE,
    EVM_OP_CREATE,
    EVM_OP_CREATE2
} from "src/lib/EVMOpcodes.sol";
import {METAMORPHIC_METADATA} from "test/lib/LibExtrospectBytecode.testConstants.sol";
import {LibExtrospectionSlow} from "test/lib/LibExtrospectionSlow.sol";
import {HasSelfdestruct} from "test/concrete/HasSelfdestruct.sol";
import {HasDelegatecall} from "test/concrete/HasDelegatecall.sol";
import {HasCallcode} from "test/concrete/HasCallcode.sol";
import {HasCreate} from "test/concrete/HasCreate.sol";
import {HasCreate2} from "test/concrete/HasCreate2.sol";
import {CleanContract} from "test/concrete/CleanContract.sol";

contract LibExtrospectMetamorphicScanMetamorphicRiskTest is Test {
    /// External wrapper for EOF revert test.
    function scanMetamorphicRiskExternal(bytes memory bytecode) external pure returns (uint256) {
        return LibExtrospectMetamorphic.scanMetamorphicRisk(bytecode);
    }

    /// Empty bytecode has no metamorphic risk.
    function testScanMetamorphicRiskEmpty() external pure {
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(hex""), 0);
    }

    /// Clean contract with no metamorphic ops returns 0.
    function testScanMetamorphicRiskClean() external {
        CleanContract clean = new CleanContract();
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(address(clean).code), 0);
    }

    /// METAMORPHIC_METADATA has SELFDESTRUCT reachable via metadata.
    function testScanMetamorphicRiskMetamorphicMetadata() external pure {
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(METAMORPHIC_METADATA);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(risk & (1 << uint256(EVM_OP_SELFDESTRUCT)) != 0);
    }

    /// Contract with SELFDESTRUCT detected.
    function testScanMetamorphicRiskSelfdestruct() external {
        HasSelfdestruct c = new HasSelfdestruct();
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(risk & (1 << uint256(EVM_OP_SELFDESTRUCT)) != 0);
    }

    /// Contract with DELEGATECALL detected.
    function testScanMetamorphicRiskDelegatecall() external {
        HasDelegatecall c = new HasDelegatecall();
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(risk & (1 << uint256(EVM_OP_DELEGATECALL)) != 0);
    }

    /// Contract with CALLCODE detected.
    function testScanMetamorphicRiskCallcode() external {
        HasCallcode c = new HasCallcode();
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(risk & (1 << uint256(EVM_OP_CALLCODE)) != 0);
    }

    /// Contract with CREATE detected.
    function testScanMetamorphicRiskCreate() external {
        HasCreate c = new HasCreate();
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(risk & (1 << uint256(EVM_OP_CREATE)) != 0);
    }

    /// Contract with CREATE2 detected.
    function testScanMetamorphicRiskCreate2() external {
        HasCreate2 c = new HasCreate2();
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(address(c).code);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(risk & (1 << uint256(EVM_OP_CREATE2)) != 0);
    }

    /// Fuzz test against slow reference.
    function testScanMetamorphicRiskReference(bytes memory data) external pure {
        vm.assume(!LibExtrospectBytecode.isEOFBytecode(data));
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(data), LibExtrospectionSlow.scanMetamorphicRiskSlow(data));
    }

    /// EOF bytecode reverts.
    function testScanMetamorphicRiskRevertsOnEOF() external {
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        this.scanMetamorphicRiskExternal(hex"EF00010203");
    }
}
