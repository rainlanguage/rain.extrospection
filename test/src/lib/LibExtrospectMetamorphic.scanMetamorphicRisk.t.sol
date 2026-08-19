// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
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
import {NonMetamorphic} from "test/concrete/NonMetamorphic.sol";

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
        NonMetamorphic clean = new NonMetamorphic();
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

    /// A SELFDESTRUCT byte inside the inline data of a trailing truncated
    /// PUSH32 is not reachable, so the bytecode carries no metamorphic risk.
    function testScanMetamorphicRiskTruncatedPush32Selfdestruct() external pure {
        // PUSH32 with 29 of its 32 data bytes present, the last one 0xFF.
        bytes memory bytecode = hex"7f00000000000000000000000000000000000000000000000000000000ff";
        assertEq(bytecode.length, 30);
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(bytecode), 0);
    }

    /// A DELEGATECALL byte inside the inline data of a trailing truncated
    /// PUSH2 is not reachable, so the bytecode carries no metamorphic risk.
    function testScanMetamorphicRiskTruncatedPush2Delegatecall() external pure {
        // PUSH2 with 1 of its 2 data bytes present, that byte 0xF4.
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(hex"61F4"), 0);
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

    /// `hex"00F0"` is STOP followed by CREATE. CREATE is a metamorphic op but is
    /// not REACHABLE here (no JUMPDEST resumes execution after the halt), so the
    /// risk bitmap is zero: the scan is over reachable opcodes, not present ones.
    function testScanMetamorphicRiskCreateAfterHaltNotReachable() external pure {
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(hex"00F0"), 0);
    }

    /// A bare reachable CREATE yields exactly the CREATE bit and nothing else,
    /// pinning both the mask and its polarity.
    function testScanMetamorphicRiskBareCreateExactBitmap() external pure {
        //forge-lint: disable-next-line(incorrect-shift)
        uint256 expected = uint256(1) << uint256(EVM_OP_CREATE);
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(hex"F0"), expected);
    }
}
