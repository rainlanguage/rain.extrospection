// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {Vm} from "forge-std-1.17.0/src/Vm.sol";

contract IExtrospectV3Test is Test {
    /// Every non-`private` function of every `LibExtrospect<Subject>` library
    /// under `src/lib/` binds exactly one `IExtrospectV3` function and every
    /// `IExtrospectV3` function binds exactly one of them. An interface
    /// function binds a library function when the parameter types are
    /// identical and, ignoring case, the interface name is the library name
    /// with one contiguous run of `Subject` inserted at one point, possibly
    /// empty. A function taking a `contract Vm` parameter is a cheatcode reader
    /// no on-chain concrete can expose, so it is not an entry point. Both
    /// sides are read from the build's ASTs and ABIs.
    function testIExtrospectV3BindsEveryLibraryEntryPointOnce() external view {
        string[] memory declared =
            vm.parseJsonKeys(vm.readFile("out/IExtrospectV3.sol/IExtrospectV3.json"), ".methodIdentifiers");
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
                assertEq(matches, 1, string.concat("IExtrospectV3 does not bind exactly once ", signatures[j]));
            }
        }
        for (uint256 k = 0; k < declared.length; k++) {
            assertEq(bound[k], 1, string.concat("IExtrospectV3 binds other than one entry point to ", declared[k]));
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
}
