// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {Vm} from "forge-std-1.17.0/src/Vm.sol";

import {IExtrospectV1} from "src/interface/IExtrospectV1.sol";
import {IExtrospectV2} from "src/interface/IExtrospectV2.sol";
import {LibExtrospectBytecode} from "src/lib/LibExtrospectBytecode.sol";
import {LibExtrospectMetamorphic, EIP3541_RESERVED_LEAD_BYTE} from "src/lib/LibExtrospectMetamorphic.sol";
import {EVM_OP_STOP, EVM_OP_ADD, EVM_OP_SELFDESTRUCT} from "src/lib/EVMOpcodes.sol";
import {REGISTRY_BEACON_PROXY_PREFIX, REGISTRY_BEACON_PROXY_SUFFIX} from "src/lib/LibExtrospectRegistryBeaconProxy.sol";

import {ExtrospectV2Fixture} from "test/concrete/ExtrospectV2Fixture.sol";
import {NonMetamorphic} from "test/concrete/NonMetamorphic.sol";
import {HasSelfdestruct} from "test/concrete/HasSelfdestruct.sol";
import {MockBeacon} from "test/concrete/MockBeacon.sol";
import {
    SOLIDITY_CBOR_RUNTIME_FIXTURE,
    SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED
} from "test/concrete/SolidityCBORFixture.sol";
import {LibExtrospectTestEtch} from "test/lib/LibExtrospectTestEtch.sol";
import {LibEIP7702Designator} from "test/lib/LibEIP7702Designator.sol";

/// @title IExtrospectV2Test
/// @notice Binds the `IExtrospectV2` surface to the libraries through
/// `ExtrospectV2Fixture`, a concrete that forwards every interface function
/// to the library function it names — the shape the deployable concrete in
/// rain.extrospection.deploy takes. The carried V1 surface is pinned as
/// selector-identical and behaviourally live; the address-taking verdict
/// entry points added in V2 are pinned to revert `CodelessAccount` on an
/// account with no code and to agree with the bytes entry points over an
/// account's code otherwise.
contract IExtrospectV2Test is Test {
    IExtrospectV2 internal immutable iExtrospect;

    constructor() {
        iExtrospect = IExtrospectV2(address(new ExtrospectV2Fixture()));
    }

    /// Every non-`private` function of every `LibExtrospect<Subject>` library
    /// under `src/lib/` binds exactly one `IExtrospectV2` function and every
    /// `IExtrospectV2` function binds exactly one of them. An interface
    /// function binds a library function when the parameter types are
    /// identical and, ignoring case, the interface name is the library name
    /// with one contiguous run of `Subject` inserted at one point, possibly
    /// empty. A function taking a `contract Vm` parameter is a cheatcode reader
    /// no on-chain concrete can expose, so it is not an entry point. Both
    /// sides are read from the build's ASTs and ABIs.
    function testIExtrospectV2BindsEveryLibraryEntryPointOnce() external view {
        string[] memory declared =
            vm.parseJsonKeys(vm.readFile("out/IExtrospectV2.sol/IExtrospectV2.json"), ".methodIdentifiers");
        uint256[] memory bound = new uint256[](declared.length);
        Vm.DirEntry[] memory artifacts = vm.readDir("out", 2);
        for (uint256 i = 0; i < artifacts.length; i++) {
            (string memory subject, string[] memory signatures) = this.libraryEntryPoints(artifacts[i].path);
            for (uint256 j = 0; j < signatures.length; j++) {
                uint256 matches = 0;
                for (uint256 k = 0; k < declared.length; k++) {
                    if (binds(declared[k], subject, signatures[j])) {
                        matches++;
                        bound[k]++;
                    }
                }
                assertEq(matches, 1, string.concat("IExtrospectV2 does not bind exactly once ", signatures[j]));
            }
        }
        for (uint256 k = 0; k < declared.length; k++) {
            assertEq(bound[k], 1, string.concat("IExtrospectV2 binds other than one entry point to ", declared[k]));
        }
    }

    /// The subject and entry point signatures of the library a build artifact
    /// describes, when that library is a `LibExtrospect*` under `src/lib/`;
    /// empty for any other path.
    function libraryEntryPoints(string memory path) external view returns (string memory, string[] memory) {
        bytes memory pathBytes = bytes(path);
        uint256 nameStart = pathBytes.length;
        while (nameStart > 0 && pathBytes[nameStart - 1] != "/") {
            nameStart--;
        }
        if (!hasPrefix(path, nameStart, "LibExtrospect") || !hasSuffix(path, ".json")) {
            return ("", new string[](0));
        }
        string memory artifact = vm.readFile(path);
        if (!hasPrefix(vm.parseJsonString(artifact, ".ast.absolutePath"), 0, "src/lib/")) {
            return ("", new string[](0));
        }
        string memory name = string(slice(pathBytes, nameStart, pathBytes.length - 5));
        string memory subject =
            string(slice(pathBytes, nameStart + bytes("LibExtrospect").length, pathBytes.length - 5));

        string memory functions = "";
        for (uint256 i = 0; vm.keyExistsJson(artifact, node(".ast.nodes", i)); i++) {
            string memory candidate = node(".ast.nodes", i);
            if (
                eq(vm.parseJsonString(artifact, string.concat(candidate, ".nodeType")), "ContractDefinition")
                    && eq(vm.parseJsonString(artifact, string.concat(candidate, ".name")), name)
                    && eq(vm.parseJsonString(artifact, string.concat(candidate, ".contractKind")), "library")
            ) {
                functions = string.concat(candidate, ".nodes");
            }
        }
        if (bytes(functions).length == 0) {
            return ("", new string[](0));
        }

        uint256 count = 0;
        while (vm.keyExistsJson(artifact, node(functions, count))) {
            count++;
        }
        string[] memory signatures = new string[](count);
        count = 0;
        for (uint256 i = 0; i < signatures.length; i++) {
            string memory fn = node(functions, i);
            if (
                eq(vm.parseJsonString(artifact, string.concat(fn, ".nodeType")), "FunctionDefinition")
                    && !eq(vm.parseJsonString(artifact, string.concat(fn, ".visibility")), "private")
            ) {
                string memory params = "";
                bool cheatcodeReader = false;
                string memory parameters = string.concat(fn, ".parameters.parameters");
                for (uint256 j = 0; vm.keyExistsJson(artifact, node(parameters, j)); j++) {
                    string memory paramType = vm.parseJsonString(
                        artifact, string.concat(node(parameters, j), ".typeDescriptions.typeString")
                    );
                    cheatcodeReader = cheatcodeReader || eq(paramType, "contract Vm");
                    params = string.concat(params, j == 0 ? "" : ",", paramType);
                }
                if (!cheatcodeReader) {
                    signatures[count++] =
                        string.concat(vm.parseJsonString(artifact, string.concat(fn, ".name")), "(", params, ")");
                }
            }
        }
        assembly ("memory-safe") {
            mstore(signatures, count)
        }
        return (subject, signatures);
    }

    function binds(string memory declared, string memory subject, string memory signature)
        internal
        pure
        returns (bool)
    {
        bytes memory d = lower(declared);
        bytes memory s = lower(signature);
        bytes memory subjectRun = lower(subject);
        if (d.length < s.length) {
            return false;
        }
        uint256 inserted = d.length - s.length;
        uint256 nameLength = 0;
        while (nameLength < s.length && s[nameLength] != "(") {
            nameLength++;
        }
        for (uint256 at = 0; at <= nameLength; at++) {
            if (
                eq(string(slice(d, 0, at)), string(slice(s, 0, at)))
                    && eq(string(slice(d, at + inserted, d.length)), string(slice(s, at, s.length)))
                    && contains(subjectRun, slice(d, at, at + inserted))
            ) {
                return true;
            }
        }
        return false;
    }

    function contains(bytes memory haystack, bytes memory needle) internal pure returns (bool) {
        for (uint256 i = 0; i + needle.length <= haystack.length; i++) {
            if (eq(string(slice(haystack, i, i + needle.length)), string(needle))) {
                return true;
            }
        }
        return false;
    }

    function lower(string memory s) internal pure returns (bytes memory) {
        bytes memory result = bytes(string.concat(s));
        for (uint256 i = 0; i < result.length; i++) {
            if (result[i] >= "A" && result[i] <= "Z") {
                result[i] = bytes1(uint8(result[i]) + 32);
            }
        }
        return result;
    }

    function node(string memory array, uint256 index) internal pure returns (string memory) {
        return string.concat(array, "[", vm.toString(index), "]");
    }

    function eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function hasPrefix(string memory s, uint256 start, string memory prefix) internal pure returns (bool) {
        bytes memory sBytes = bytes(s);
        return sBytes.length >= start + bytes(prefix).length
            && eq(string(slice(sBytes, start, start + bytes(prefix).length)), prefix);
    }

    function hasSuffix(string memory s, string memory suffix) internal pure returns (bool) {
        bytes memory sBytes = bytes(s);
        return sBytes.length >= bytes(suffix).length
            && eq(string(slice(sBytes, sBytes.length - bytes(suffix).length, sBytes.length)), suffix);
    }

    function slice(bytes memory b, uint256 start, uint256 end) internal pure returns (bytes memory) {
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = b[i];
        }
        return result;
    }

    /// Every function carried from `IExtrospectV1` keeps its V1 selector, so
    /// per-function tooling written against the V1 ABI reads the new deploy
    /// unchanged. Overloaded names have no unambiguous `.selector` member on
    /// V2; their bytes overloads are exercised by V1 selector below in
    /// `testIExtrospectV2AnswersIExtrospectV1OverloadedSelectors`.
    function testIExtrospectV2CarriesIExtrospectV1Selectors() external pure {
        assertEq(
            IExtrospectV2.checkCBORTrimmedBytecodeHash.selector, IExtrospectV1.checkCBORTrimmedBytecodeHash.selector
        );
        assertEq(IExtrospectV2.checkNoSolidityCBORMetadata.selector, IExtrospectV1.checkNoSolidityCBORMetadata.selector);
        assertEq(IExtrospectV2.checkNotEOFBytecode.selector, IExtrospectV1.checkNotEOFBytecode.selector);
        assertEq(IExtrospectV2.isEOFBytecode.selector, IExtrospectV1.isEOFBytecode.selector);
        assertEq(IExtrospectV2.isERC1167Proxy.selector, IExtrospectV1.isERC1167Proxy.selector);
        assertEq(IExtrospectV2.tryTrimSolidityCBORMetadata.selector, IExtrospectV1.tryTrimSolidityCBORMetadata.selector);
    }

    /// The four names V2 overloads answer their V1 (bytes-taking) selectors
    /// with the library's verdicts: raw calls encoded from the V1 ABI land on
    /// the V2 fixture and return what the libraries return.
    function testIExtrospectV2AnswersIExtrospectV1OverloadedSelectors() external view {
        (bool ok, bytes memory ret) = address(iExtrospect)
            .staticcall(abi.encodeWithSelector(IExtrospectV1.scanMetamorphicRisk.selector, bytes(hex"ff")));
        assertTrue(ok);
        assertEq(abi.decode(ret, (uint256)), uint256(1) << EVM_OP_SELFDESTRUCT);

        (ok, ret) = address(iExtrospect)
            .staticcall(abi.encodeWithSelector(IExtrospectV1.checkNotMetamorphic.selector, bytes(hex"0001")));
        assertTrue(ok);
        assertEq(ret.length, 0);

        (ok, ret) = address(iExtrospect)
            .staticcall(
                abi.encodeWithSelector(IExtrospectV1.scanEVMOpcodesPresentInBytecode.selector, bytes(hex"0001"))
            );
        assertTrue(ok);
        assertEq(abi.decode(ret, (uint256)), (uint256(1) << EVM_OP_STOP) | (uint256(1) << EVM_OP_ADD));

        (ok, ret) = address(iExtrospect)
            .staticcall(
                abi.encodeWithSelector(IExtrospectV1.scanEVMOpcodesReachableInBytecode.selector, bytes(hex"0001"))
            );
        assertTrue(ok);
        assertEq(abi.decode(ret, (uint256)), uint256(1) << EVM_OP_STOP);
    }

    /// Carried surface: `checkCBORTrimmedBytecodeHash` passes on the trimmed
    /// hash of code carrying the standard trailer, reverts
    /// `BytecodeHashMismatch` on any other hash, and reverts
    /// `MetadataNotTrimmed` for an account compiled without metadata.
    function testIExtrospectV2CheckCBORTrimmedBytecodeHash() external {
        address target = address(0xBEEF);
        vm.etch(target, SOLIDITY_CBOR_RUNTIME_FIXTURE);
        iExtrospect.checkCBORTrimmedBytecodeHash(target, keccak256(SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED));

        bytes32 wrong = keccak256("wrong");
        vm.expectRevert(
            abi.encodeWithSelector(
                LibExtrospectBytecode.BytecodeHashMismatch.selector,
                wrong,
                keccak256(SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED)
            )
        );
        iExtrospect.checkCBORTrimmedBytecodeHash(target, wrong);

        NonMetamorphic noMetadata = new NonMetamorphic();
        vm.expectRevert(LibExtrospectBytecode.MetadataNotTrimmed.selector);
        iExtrospect.checkCBORTrimmedBytecodeHash(address(noMetadata), keccak256(address(noMetadata).code));
    }

    /// Carried surface: `checkNoSolidityCBORMetadata` passes on an account
    /// compiled without metadata, reverts `UnexpectedMetadata` on the standard
    /// trailer, and reverts `CodelessAccount` on an account with no code.
    function testIExtrospectV2CheckNoSolidityCBORMetadata() external {
        NonMetamorphic clean = new NonMetamorphic();
        iExtrospect.checkNoSolidityCBORMetadata(address(clean));

        address target = address(0xBEEF);
        vm.etch(target, SOLIDITY_CBOR_RUNTIME_FIXTURE);
        vm.expectRevert(LibExtrospectBytecode.UnexpectedMetadata.selector);
        iExtrospect.checkNoSolidityCBORMetadata(target);

        address codeless = address(0xC2);
        assertEq(codeless.code.length, 0);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.CodelessAccount.selector, codeless));
        iExtrospect.checkNoSolidityCBORMetadata(codeless);
    }

    /// Carried surface: `checkNotEOFBytecode` and `isEOFBytecode` gate on the
    /// two byte EOF magic `0xEF00` only. A bare `0xEF` and the `0xEF01` of an
    /// EIP-7702 delegation designator are not EOF.
    function testIExtrospectV2EOFBytecode() external {
        assertTrue(iExtrospect.isEOFBytecode(hex"ef00"));
        assertTrue(iExtrospect.isEOFBytecode(hex"ef0001"));
        assertFalse(iExtrospect.isEOFBytecode(hex""));
        assertFalse(iExtrospect.isEOFBytecode(hex"ef"));
        assertFalse(iExtrospect.isEOFBytecode(LibEIP7702Designator.designator(address(0xDE1E647E))));

        iExtrospect.checkNotEOFBytecode(hex"");
        iExtrospect.checkNotEOFBytecode(hex"ef");
        iExtrospect.checkNotEOFBytecode(LibEIP7702Designator.designator(address(0xDE1E647E)));
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        iExtrospect.checkNotEOFBytecode(hex"ef00");
    }

    /// Carried surface: `checkNotMetamorphic(bytes)` stays total over bytes.
    /// Empty bytecode passes — whether an account has code at all is not
    /// checked at the bytes boundary — clean code passes, reachable
    /// metamorphic opcodes revert `Metamorphic` with the scan's bitmap, and
    /// any `0xEF` lead byte fails closed to `Metamorphic(1 << 0xEF)`.
    function testIExtrospectV2CheckNotMetamorphicBytes() external {
        iExtrospect.checkNotMetamorphic(hex"");

        NonMetamorphic clean = new NonMetamorphic();
        iExtrospect.checkNotMetamorphic(address(clean).code);

        HasSelfdestruct risky = new HasSelfdestruct();
        uint256 risk = iExtrospect.scanMetamorphicRisk(address(risky).code);
        assertTrue(risk != 0);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        iExtrospect.checkNotMetamorphic(address(risky).code);

        vm.expectRevert(
            abi.encodeWithSelector(
                LibExtrospectMetamorphic.Metamorphic.selector, uint256(1) << EIP3541_RESERVED_LEAD_BYTE
            )
        );
        iExtrospect.checkNotMetamorphic(hex"ef");
    }

    /// Carried surface: `isERC1167Proxy` recognises the 45 byte minimal proxy
    /// and extracts its implementation address.
    function testIExtrospectV2IsERC1167Proxy() external view {
        address implementation = address(0x1234567890123456789012345678901234567890);
        bytes memory proxy =
            abi.encodePacked(hex"363d3d373d3d3d363d73", implementation, hex"5af43d82803e903d91602b57fd5bf3");
        (bool result, address extracted) = iExtrospect.isERC1167Proxy(proxy);
        assertTrue(result);
        assertEq(extracted, implementation);

        (result, extracted) = iExtrospect.isERC1167Proxy(hex"00");
        assertFalse(result);
        assertEq(extracted, address(0));
    }

    function testIExtrospectV2IsRegistryBeaconProxy(address beacon) external view {
        vm.assume(beacon != address(0));
        (bool result, address extracted) = iExtrospect.isRegistryBeaconProxy(
            abi.encodePacked(
                REGISTRY_BEACON_PROXY_PREFIX, bytes32(uint256(uint160(beacon))), REGISTRY_BEACON_PROXY_SUFFIX
            )
        );
        assertTrue(result);
        assertEq(extracted, beacon);

        (result, extracted) = iExtrospect.isRegistryBeaconProxy(hex"00");
        assertFalse(result);
        assertEq(extracted, address(0));
    }

    /// Carried surface: the beacon predicates answer over a mock beacon.
    function testIExtrospectV2BeaconPredicates() external {
        NonMetamorphic implementation = new NonMetamorphic();
        address owner = address(0x0111);
        MockBeacon beacon = new MockBeacon(address(implementation), owner);

        assertTrue(
            iExtrospect.isERC1967BeaconImplementationBytecode(address(beacon), keccak256(address(implementation).code))
        );
        assertFalse(iExtrospect.isERC1967BeaconImplementationBytecode(address(beacon), keccak256("wrong")));

        assertTrue(iExtrospect.isERC1967BeaconOwner(address(beacon), owner));
        assertFalse(iExtrospect.isERC1967BeaconOwner(address(beacon), address(0x0222)));
    }

    /// Carried surface: `tryTrimSolidityCBORMetadata` trims the standard
    /// trailer on the callee's copy and returns it; the caller's own bytes
    /// are untouched across the external boundary. Unrecognised bytes come
    /// back unchanged with a false verdict.
    function testIExtrospectV2TryTrimSolidityCBORMetadata() external view {
        bytes memory bytecode = SOLIDITY_CBOR_RUNTIME_FIXTURE;
        (bool didTrim, bytes memory trimmed) = iExtrospect.tryTrimSolidityCBORMetadata(bytecode);
        assertTrue(didTrim);
        assertEq(trimmed, SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED);
        assertEq(bytecode.length, SOLIDITY_CBOR_RUNTIME_FIXTURE.length);

        (bool didTrimAgain, bytes memory untrimmed) =
            iExtrospect.tryTrimSolidityCBORMetadata(SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED);
        assertFalse(didTrimAgain);
        assertEq(untrimmed, SOLIDITY_CBOR_RUNTIME_FIXTURE_TRIMMED);
    }

    /// V2 surface: `checkNotMetamorphic(address)` reverts `CodelessAccount`
    /// carrying the address when the account has no code. The bytes entry
    /// point passes the same account's empty code, pinning that only the
    /// address boundary refuses to vouch for a codeless account.
    function testIExtrospectV2CheckNotMetamorphicAddressRevertsOnCodelessAccount() external {
        address codeless = address(0xC2);
        assertEq(codeless.code.length, 0);
        iExtrospect.checkNotMetamorphic(codeless.code);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.CodelessAccount.selector, codeless));
        iExtrospect.checkNotMetamorphic(codeless);
    }

    /// V2 surface: `scanMetamorphicRisk(address)` reverts `CodelessAccount`
    /// carrying the address when the account has no code. The bytes entry
    /// point scans the same account's empty code to zero.
    function testIExtrospectV2ScanMetamorphicRiskAddressRevertsOnCodelessAccount() external {
        address codeless = address(0xC2);
        assertEq(codeless.code.length, 0);
        assertEq(iExtrospect.scanMetamorphicRisk(codeless.code), 0);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.CodelessAccount.selector, codeless));
        iExtrospect.scanMetamorphicRisk(codeless);
    }

    /// V2 surface: `scanEVMOpcodesPresentInBytecode(address)` reverts
    /// `CodelessAccount` carrying the address when the account has no code.
    /// The bytes entry point scans the same account's empty code to zero.
    function testIExtrospectV2ScanPresentAddressRevertsOnCodelessAccount() external {
        address codeless = address(0xC2);
        assertEq(codeless.code.length, 0);
        assertEq(iExtrospect.scanEVMOpcodesPresentInBytecode(codeless.code), 0);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.CodelessAccount.selector, codeless));
        iExtrospect.scanEVMOpcodesPresentInBytecode(codeless);
    }

    /// V2 surface: `scanEVMOpcodesReachableInBytecode(address)` reverts
    /// `CodelessAccount` carrying the address when the account has no code.
    /// The bytes entry point scans the same account's empty code to zero.
    function testIExtrospectV2ScanReachableAddressRevertsOnCodelessAccount() external {
        address codeless = address(0xC2);
        assertEq(codeless.code.length, 0);
        assertEq(iExtrospect.scanEVMOpcodesReachableInBytecode(codeless.code), 0);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectBytecode.CodelessAccount.selector, codeless));
        iExtrospect.scanEVMOpcodesReachableInBytecode(codeless);
    }

    /// V2 surface: for an account with code the metamorphic pair binds the
    /// bytes verdicts to the account: clean passes, reachable metamorphic
    /// opcodes revert `Metamorphic` with the same bitmap the bytes scan
    /// reports.
    function testIExtrospectV2MetamorphicAddressAgreesWithBytes() external {
        NonMetamorphic clean = new NonMetamorphic();
        iExtrospect.checkNotMetamorphic(address(clean));
        assertEq(iExtrospect.scanMetamorphicRisk(address(clean)), 0);

        HasSelfdestruct risky = new HasSelfdestruct();
        uint256 risk = iExtrospect.scanMetamorphicRisk(address(risky).code);
        assertTrue(risk != 0);
        assertEq(iExtrospect.scanMetamorphicRisk(address(risky)), risk);
        vm.expectRevert(abi.encodeWithSelector(LibExtrospectMetamorphic.Metamorphic.selector, risk));
        iExtrospect.checkNotMetamorphic(address(risky));
    }

    /// V2 surface: account code carrying an EIP-7702 delegation designator
    /// (`0xEF0100 || address`) fails closed on the metamorphic pair to
    /// exactly `1 << 0xEF`, never `EOFBytecodeNotSupported`.
    function testIExtrospectV2MetamorphicAddressFailsClosedOnEIP7702Designator() external {
        address target = address(0xBEEF);
        vm.etch(target, LibEIP7702Designator.designator(address(0xDE1E647E)));
        assertEq(iExtrospect.scanMetamorphicRisk(target), uint256(1) << EIP3541_RESERVED_LEAD_BYTE);
        vm.expectRevert(
            abi.encodeWithSelector(
                LibExtrospectMetamorphic.Metamorphic.selector, uint256(1) << EIP3541_RESERVED_LEAD_BYTE
            )
        );
        iExtrospect.checkNotMetamorphic(target);
    }

    /// V2 surface: the same account code splits the two verdict families.
    /// EOF code (`0xEF00` lead) reverts `EOFBytecodeNotSupported` on the raw
    /// opcode scans, which gate on the two byte EOF magic only, while the
    /// metamorphic pair fails closed to `Metamorphic(1 << 0xEF)` on the lead
    /// byte alone and never reverts `EOFBytecodeNotSupported`.
    function testIExtrospectV2AddressEntryPointsSplitOnEOFCode() external {
        address target = address(0xBEEF);
        vm.etch(target, hex"ef00");

        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        iExtrospect.scanEVMOpcodesPresentInBytecode(target);
        vm.expectRevert(LibExtrospectBytecode.EOFBytecodeNotSupported.selector);
        iExtrospect.scanEVMOpcodesReachableInBytecode(target);

        assertEq(iExtrospect.scanMetamorphicRisk(target), uint256(1) << EIP3541_RESERVED_LEAD_BYTE);
        vm.expectRevert(
            abi.encodeWithSelector(
                LibExtrospectMetamorphic.Metamorphic.selector, uint256(1) << EIP3541_RESERVED_LEAD_BYTE
            )
        );
        iExtrospect.checkNotMetamorphic(target);
    }

    /// V2 surface: a bare `0xEF` lead byte that is not the EOF magic does not
    /// trip the raw scans' EOF gate — the byte scans as an ordinary unassigned
    /// opcode — while the metamorphic pair still fails closed on it.
    function testIExtrospectV2AddressEntryPointsSplitOnBare0xEF() external {
        address target = address(0xBEEF);
        vm.etch(target, hex"ef");

        assertEq(iExtrospect.scanEVMOpcodesPresentInBytecode(target), uint256(1) << EIP3541_RESERVED_LEAD_BYTE);
        assertEq(iExtrospect.scanEVMOpcodesReachableInBytecode(target), uint256(1) << EIP3541_RESERVED_LEAD_BYTE);
        assertEq(iExtrospect.scanMetamorphicRisk(target), uint256(1) << EIP3541_RESERVED_LEAD_BYTE);
    }

    /// V2 surface: for an account with code the opcode scans report the same
    /// bitmaps as the bytes scans over that account's code, and present and
    /// reachable stay distinct scans: code with a region after a halt and
    /// before any `JUMPDEST` sets present bits that reachable omits.
    function testIExtrospectV2OpcodeScanAddressAgreesWithBytes() external {
        address target = address(0xBEEF);
        vm.etch(target, SOLIDITY_CBOR_RUNTIME_FIXTURE);

        uint256 present = iExtrospect.scanEVMOpcodesPresentInBytecode(SOLIDITY_CBOR_RUNTIME_FIXTURE);
        uint256 reachable = iExtrospect.scanEVMOpcodesReachableInBytecode(SOLIDITY_CBOR_RUNTIME_FIXTURE);
        assertTrue(present != reachable);

        assertEq(iExtrospect.scanEVMOpcodesPresentInBytecode(target), present);
        assertEq(iExtrospect.scanEVMOpcodesReachableInBytecode(target), reachable);
    }

    /// Fuzz: for an account with nonempty etchable non-EOF code, every V2
    /// address entry point agrees with its bytes entry point over the
    /// account's code.
    function testIExtrospectV2AddressEntryPointsAgreeWithBytesFuzz(bytes memory code) external {
        vm.assume(code.length > 0);
        vm.assume(!iExtrospect.isEOFBytecode(code));
        address target = address(0xBEEF);
        LibExtrospectTestEtch.assumeEtch(vm, target, code);

        assertEq(iExtrospect.scanEVMOpcodesPresentInBytecode(target), iExtrospect.scanEVMOpcodesPresentInBytecode(code));
        assertEq(
            iExtrospect.scanEVMOpcodesReachableInBytecode(target), iExtrospect.scanEVMOpcodesReachableInBytecode(code)
        );
        assertEq(iExtrospect.scanMetamorphicRisk(target), iExtrospect.scanMetamorphicRisk(code));
    }
}
