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
import {CreateChildFactory} from "test/concrete/CreateChildFactory.sol";
import {Create2ChildFactory} from "test/concrete/Create2ChildFactory.sol";
import {ChildLeaf} from "test/concrete/ChildLeaf.sol";
import {NonMetamorphic} from "test/concrete/NonMetamorphic.sol";
import {LibExtrospectTestEtch} from "test/lib/LibExtrospectTestEtch.sol";

contract LibExtrospectMetamorphicScanMetamorphicRiskTest is Test {
    /// External wrapper for address entry point revert tests.
    function scanMetamorphicRiskAddressExternal(address account) external view returns (uint256) {
        return LibExtrospectMetamorphic.scanMetamorphicRisk(account);
    }

    /// Address entry point: a codeless account reverts with `CodelessAccount`
    /// carrying the address. The bytes entry point returns zero for the same
    /// account's (empty) code, pinned by
    /// `testScanMetamorphicRiskCodelessAccount`; only the address boundary can
    /// refuse to vouch for a codeless account.
    function testScanMetamorphicRiskAddressRevertsOnCodelessAccount() external {
        address codeless = address(0xC2);
        assertEq(codeless.code.length, 0);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.CodelessAccount.selector, codeless));
        this.scanMetamorphicRiskAddressExternal(codeless);
    }

    /// Address entry point: clean contract scans to zero.
    function testScanMetamorphicRiskAddressClean() external {
        NonMetamorphic clean = new NonMetamorphic();
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(address(clean)), 0);
    }

    /// Address entry point: contract with SELFDESTRUCT scans with the
    /// SELFDESTRUCT bit set, same as the bytes entry point over its code.
    function testScanMetamorphicRiskAddressSelfdestruct() external {
        HasSelfdestruct c = new HasSelfdestruct();
        uint256 risk = LibExtrospectMetamorphic.scanMetamorphicRisk(address(c));
        //forge-lint: disable-next-line(incorrect-shift)
        assertTrue(risk & (1 << uint256(EVM_OP_SELFDESTRUCT)) != 0);
        assertEq(risk, LibExtrospectMetamorphic.scanMetamorphicRisk(address(c).code));
    }

    /// Address entry point: EOF code etched onto an account reports the
    /// EIP-3541 reserved `0xEF` lead byte as the risky element, via delegation
    /// to the bytes entry point.
    function testScanMetamorphicRiskAddressEOFReservedPrefix() external {
        address target = address(0xBEEF);
        vm.etch(target, hex"EF00010203");
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(target), uint256(1) << 0xEF);
    }

    /// Address entry point: an account whose code is an EIP-7702 delegation
    /// designator reports the EIP-3541 reserved `0xEF` lead byte as the risky
    /// element, via delegation to the bytes entry point.
    function testScanMetamorphicRiskAddressEIP7702DelegationDesignator() external {
        address target = address(0xBEEF);
        vm.etch(target, abi.encodePacked(hex"ef0100", address(0x1234567890123456789012345678901234567890)));
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(target), uint256(1) << 0xEF);
    }

    /// Fuzz: for an account with nonempty etchable code, the address entry
    /// point returns exactly what the bytes entry point returns for that code.
    /// EOF code and EIP-7702 delegation designators are included: both entry
    /// points report `1 << 0xEF` for them.
    function testScanMetamorphicRiskAddressEquivalenceFuzz(bytes memory code) external {
        vm.assume(code.length > 0);
        address target = address(0xBEEF);
        LibExtrospectTestEtch.assumeEtch(vm, target, code);

        assertEq(
            LibExtrospectMetamorphic.scanMetamorphicRisk(target), LibExtrospectMetamorphic.scanMetamorphicRisk(code)
        );
    }

    /// Empty bytecode has no metamorphic risk.
    function testScanMetamorphicRiskEmpty() external pure {
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(hex""), 0);
    }

    /// An account with no code reads as empty bytecode and so has no
    /// metamorphic risk.
    function testScanMetamorphicRiskCodelessAccount() external view {
        address codeless = address(0xC2);
        assertEq(codeless.code.length, 0);
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(codeless.code), 0);
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

    /// A factory whose own runtime code has no SELFDESTRUCT, DELEGATECALL or
    /// CALLCODE, and which deploys a single fixed child type with CREATE, scans
    /// as risky on the CREATE bit alone. The child scans clean.
    function testScanMetamorphicRiskCreateChildFactory() external {
        CreateChildFactory factory = new CreateChildFactory();
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(address(factory).code), 1 << uint256(EVM_OP_CREATE));
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(address(new ChildLeaf()).code), 0);
    }

    /// A factory whose own runtime code has no SELFDESTRUCT, DELEGATECALL or
    /// CALLCODE, and which deploys a single fixed child type with CREATE2, scans
    /// as risky on the CREATE2 bit alone. The child scans clean.
    function testScanMetamorphicRiskCreate2ChildFactory() external {
        Create2ChildFactory factory = new Create2ChildFactory();
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(address(factory).code), 1 << uint256(EVM_OP_CREATE2));
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(address(new ChildLeaf()).code), 0);
    }

    /// SELFDESTRUCT after STOP with no JUMPDEST is present in the bytecode but
    /// not reachable, so it is not risky.
    function testScanMetamorphicRiskUnreachableSelfdestruct() external pure {
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(hex"00FF"), 0);
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

    /// Fuzz test against slow reference, total over all bytes: the scan
    /// never reverts, including on the EIP-3541 reserved `0xEF` prefix.
    function testScanMetamorphicRiskReference(bytes memory data) external pure {
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(data), LibExtrospectionSlow.scanMetamorphicRiskSlow(data));
    }

    /// EOF bytecode reports the EIP-3541 reserved `0xEF` lead byte as the
    /// risky element instead of reverting `EOFBytecodeNotSupported`.
    function testScanMetamorphicRiskEOFReservedPrefix() external pure {
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(hex"EF00010203"), uint256(1) << 0xEF);
    }

    /// The EIP-7702 delegation designator `0xEF0100 || address` reports the
    /// EIP-3541 reserved `0xEF` lead byte as the risky element. The account
    /// holder can repoint or revoke the delegation with one transaction, so
    /// the code at the account is the live "different code at the same
    /// address" case. Inverts the repro on #54, which pinned a zero scan.
    /// `isEOFBytecode` stays `false` for the designator per #53: the gate
    /// lives in the metamorphic scan, not in the EOF predicate.
    function testScanMetamorphicRiskEIP7702DelegationDesignator() external pure {
        bytes memory designator = abi.encodePacked(hex"ef0100", address(0x1234567890123456789012345678901234567890));
        assertEq(designator.length, 23);
        assertFalse(LibExtrospectBytecode.isEOFBytecode(designator));
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(designator), uint256(1) << 0xEF);
    }

    /// The designator verdict does not depend on the delegate address's hex
    /// digits. This delegate spells `JUMPDEST DELEGATECALL` in its leading
    /// bytes, which previously resumed the legacy scan inside the address and
    /// flipped the verdict to `1 << DELEGATECALL`; now every designator
    /// reports the same `0xEF` bit.
    function testScanMetamorphicRiskEIP7702DelegationDesignatorDelegateIndependent() external pure {
        bytes memory designator = abi.encodePacked(hex"ef0100", address(0x5BF4000000000000000000000000000000000000));
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(designator), uint256(1) << 0xEF);
    }

    /// A single bare `0xEF` byte reports itself as the risky element: the
    /// fail-closed rule is the first byte alone, not any longer prefix shape.
    function testScanMetamorphicRiskBareReservedByte() external pure {
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(hex"EF"), uint256(1) << 0xEF);
    }

    /// An EOF container of a future version (`0xEF02...`) reports the
    /// EIP-3541 reserved `0xEF` lead byte as the risky element: the rule
    /// covers every future assignment of the prefix, not a registry of known
    /// formats.
    function testScanMetamorphicRiskFutureReservedPrefix() external pure {
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(hex"EF02010203"), uint256(1) << 0xEF);
    }

    /// Fuzz: ANY bytecode whose first byte is `0xEF` scans to exactly
    /// `1 << 0xEF`, whatever follows the first byte.
    function testScanMetamorphicRiskReservedPrefixFuzz(bytes memory tail) external pure {
        bytes memory bytecode = abi.encodePacked(hex"ef", tail);
        //forge-lint: disable-next-line(incorrect-shift)
        assertEq(LibExtrospectMetamorphic.scanMetamorphicRisk(bytecode), uint256(1) << 0xEF);
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
