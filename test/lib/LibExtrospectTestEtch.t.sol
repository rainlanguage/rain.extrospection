// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibExtrospectTestEtch} from "test/lib/LibExtrospectTestEtch.sol";

contract LibExtrospectTestEtchTest is Test {
    address constant TARGET = address(0xBEEF);

    /// The 33 byte counterexample foundry produced for the CBOR metadata fuzz
    /// tests before they routed their etches through `assumeEtch`.
    bytes constant COUNTEREXAMPLE = hex"ef01e8ca4630bc62619fd019a890e4de496295ee3586eebdb070893a2228228150";

    /// A well formed EIP-7702 delegation designator: `0xef0100` then 20 address
    /// bytes.
    bytes constant DESIGNATOR = hex"ef01001234567890123456789012345678901234567890";

    /// External wrapper so a rejected run is observable as revert data.
    function assumeEtchExternal(address target, bytes memory code) external {
        LibExtrospectTestEtch.assumeEtch(vm, target, code);
    }

    /// Asserts the predicate says `expected` and that `vm.etch` agrees.
    //forge-lint: disable-next-line(mixed-case-function)
    function checkEtchAccepts(bytes memory code, bool expected) internal {
        assertEq(LibExtrospectTestEtch.etchAcceptsEIP7702(code), expected, "predicate");
        (bool ok,) = address(vm).call(abi.encodeWithSignature("etch(address,bytes)", TARGET, code));
        assertEq(ok, expected, "vm.etch");
    }

    function testEtchAcceptsEmpty() external {
        checkEtchAccepts(hex"", true);
    }

    //forge-lint: disable-next-line(mixed-case-function)
    function testEtchAcceptsBareEF() external {
        checkEtchAccepts(hex"ef", true);
    }

    //forge-lint: disable-next-line(mixed-case-function)
    function testEtchAcceptsEOFPrefix() external {
        checkEtchAccepts(hex"ef00", true);
        checkEtchAccepts(hex"ef00010203", true);
        checkEtchAccepts(hex"ef00000000000000000000000000000000000000000000", true);
    }

    /// `0xEF` followed by anything other than `0x00` or `0x01`.
    //forge-lint: disable-next-line(mixed-case-function)
    function testEtchAcceptsOtherEFPrefixes() external {
        checkEtchAccepts(hex"ef02010203", true);
        checkEtchAccepts(hex"efff010203", true);
    }

    function testEtchAcceptsLegacyBytecode() external {
        checkEtchAccepts(hex"6080604052600080fd", true);
    }

    //forge-lint: disable-next-line(mixed-case-function)
    function testEtchAcceptsEIP7702Designator() external {
        assertEq(DESIGNATOR.length, 23);
        checkEtchAccepts(DESIGNATOR, true);
    }

    /// `0xEF01` at exactly two bytes has no version byte and no address.
    //forge-lint: disable-next-line(mixed-case-function)
    function testEtchRejectsEIP7702PrefixAlone() external {
        checkEtchAccepts(hex"ef01", false);
    }

    //forge-lint: disable-next-line(mixed-case-function)
    function testEtchRejectsEIP7702PrefixTooShort() external {
        checkEtchAccepts(hex"ef01010203", false);
        checkEtchAccepts(hex"ef01093be21bc41c9151025546b30e304c0b4c", false);
    }

    /// 24 bytes: one byte longer than a designator.
    //forge-lint: disable-next-line(mixed-case-function)
    function testEtchRejectsEIP7702PrefixTooLong() external {
        bytes memory code = hex"ef0100123456789012345678901234567890123456789012";
        assertEq(code.length, 24);
        checkEtchAccepts(code, false);
    }

    /// 23 bytes with a non zero version byte.
    //forge-lint: disable-next-line(mixed-case-function)
    function testEtchRejectsEIP7702BadVersion() external {
        bytes memory code = hex"ef01991234567890123456789012345678901234567890";
        assertEq(code.length, 23);
        checkEtchAccepts(code, false);
    }

    //forge-lint: disable-next-line(mixed-case-function)
    function testEtchRejectsEIP7702Counterexample() external {
        assertEq(COUNTEREXAMPLE.length, 33);
        checkEtchAccepts(COUNTEREXAMPLE, false);
    }

    /// Accepted code is etched at the target.
    function testAssumeEtchSetsCode() external {
        bytes memory code = hex"6080604052600080fd";
        LibExtrospectTestEtch.assumeEtch(vm, TARGET, code);
        assertEq(TARGET.code, code);
    }

    /// An accepted `0xEF00` prefix is etched rather than rejected.
    //forge-lint: disable-next-line(mixed-case-function)
    function testAssumeEtchSetsEOFCode() external {
        bytes memory code = hex"ef00010203";
        LibExtrospectTestEtch.assumeEtch(vm, TARGET, code);
        assertEq(TARGET.code, code);
    }

    /// Rejected code discards the run through `vm.assume` instead of reaching
    /// `vm.etch` and failing the test.
    function testAssumeEtchRejectsRun() external {
        (bool ok, bytes memory err) =
            address(this).call(abi.encodeWithSelector(this.assumeEtchExternal.selector, TARGET, COUNTEREXAMPLE));
        assertFalse(ok);
        assertEq(err, bytes("FOUNDRY::ASSUME"));
        assertEq(TARGET.code.length, 0);
    }
}
