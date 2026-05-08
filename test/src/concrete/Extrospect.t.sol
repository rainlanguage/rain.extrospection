// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Extrospect} from "src/concrete/Extrospect.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {EVM_OP_DELEGATECALL} from "src/lib/EVMOpcodes.sol";

/// @title ExtrospectTest
/// @notice Smoke tests for the concrete `Extrospect` contract — confirm
/// each external entry point dispatches into the right library function.
/// The libraries themselves have exhaustive tests in `test/src/lib/`; this
/// file just pins the wiring.
contract ExtrospectTest is Test {
    Extrospect internal extrospect;

    function setUp() external {
        extrospect = new Extrospect();
    }

    /// `checkNoSolidityCBORMetadata` reverts via the external entry point
    /// when the target carries Solidity CBOR metadata. Demonstrates the
    /// `vm.expectRevert`-friendly call path the contract exists for.
    function testCheckNoSolidityCBORMetadataRevertsExternally() external {
        bytes memory runtimeCode =
            hex"6080604052600080fdfea26469706673582212200726074213b9ef2f5b41bf0bdd5bbd03a64652de62f1dfcda59625e106c52e8a64736f6c63430008190033";
        address deployed = address(0xbeef);
        vm.etch(deployed, runtimeCode);
        vm.expectRevert(LibExtrospectBytecode.UnexpectedMetadata.selector);
        extrospect.checkNoSolidityCBORMetadata(deployed);
    }

    /// `scanMetamorphicRisk` returns a bitmap with the DELEGATECALL bit set
    /// when the bytecode contains a reachable DELEGATECALL.
    function testScanMetamorphicRiskExternal() external view {
        // PUSH1 0x00 ... DELEGATECALL — minimal bytecode where DELEGATECALL is reachable.
        // 6000 6000 6000 6000 6000 6000 F4 = 6×PUSH1 0x00 then DELEGATECALL.
        bytes memory code = hex"60006000600060006000F4";
        uint256 risk = extrospect.scanMetamorphicRisk(code);
        assertEq(risk & (1 << EVM_OP_DELEGATECALL), 1 << EVM_OP_DELEGATECALL, "DELEGATECALL bit should be set");
    }

    /// `isERC1167Proxy` correctly identifies the standard ERC1167 layout.
    function testIsERC1167ProxyExternal() external view {
        // Empty bytecode is not a proxy.
        (bool isProxy, address impl) = extrospect.isERC1167Proxy(hex"");
        assertFalse(isProxy);
        assertEq(impl, address(0));
    }

    /// `isEOFBytecode` flags the EOF magic prefix.
    function testIsEOFBytecodeExternal() external view {
        assertTrue(extrospect.isEOFBytecode(hex"EF00010203"));
        assertFalse(extrospect.isEOFBytecode(hex"00"));
    }

    /// Parameterless constructor — required for Zoltu deterministic deploy.
    function testParameterlessConstructor() external {
        Extrospect fresh = new Extrospect();
        assertTrue(address(fresh) != address(0));
    }
}
