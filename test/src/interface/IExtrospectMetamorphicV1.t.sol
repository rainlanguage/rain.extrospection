// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibCtPop} from "rain.math.binary/lib/LibCtPop.sol";
import {
    METAMORPHIC_OPS,
    EVM_OP_SELFDESTRUCT,
    EVM_OP_DELEGATECALL,
    EVM_OP_CALLCODE,
    EVM_OP_CREATE,
    EVM_OP_CREATE2
} from "src/lib/EVMOpcodes.sol";

contract IExtrospectMetamorphicV1Test is Test {
    /// METAMORPHIC_OPS must contain exactly the 5 expected opcodes.
    function testMetamorphicOpsPopcount() external pure {
        assertEq(LibCtPop.ctpop(METAMORPHIC_OPS), 5);
    }

    /// Validate the raw bitmap value using independent hex opcode values.
    function testMetamorphicOpsRawValue() external pure {
        // SELFDESTRUCT=0xFF, DELEGATECALL=0xF4, CALLCODE=0xF2,
        // CREATE=0xF0, CREATE2=0xF5
        //forge-lint: disable-next-line(incorrect-shift)
        uint256 expected = (1 << 0xFF) | (1 << 0xF4) | (1 << 0xF2) | (1 << 0xF0) | (1 << 0xF5);
        assertEq(METAMORPHIC_OPS, expected);
    }

    /// Each individual opcode bit is set.
    function testMetamorphicOpsIndividualBits() external pure {
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(METAMORPHIC_OPS & (1 << uint256(EVM_OP_SELFDESTRUCT)) != 0);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(METAMORPHIC_OPS & (1 << uint256(EVM_OP_DELEGATECALL)) != 0);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(METAMORPHIC_OPS & (1 << uint256(EVM_OP_CALLCODE)) != 0);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(METAMORPHIC_OPS & (1 << uint256(EVM_OP_CREATE)) != 0);
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(METAMORPHIC_OPS & (1 << uint256(EVM_OP_CREATE2)) != 0);
    }

    /// Opcodes NOT in the metamorphic set.
    function testMetamorphicOpsExclusions() external pure {
        // STATICCALL (0xFA), CALL (0xF1), RETURN (0xF3) should NOT be set.
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(METAMORPHIC_OPS & (1 << 0xFA), 0);
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(METAMORPHIC_OPS & (1 << 0xF1), 0);
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(METAMORPHIC_OPS & (1 << 0xF3), 0);
    }
}
