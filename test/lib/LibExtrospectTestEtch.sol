// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {Vm} from "forge-std-1.16.1/src/Vm.sol";

library LibExtrospectTestEtch {
    /// True when `vm.etch` accepts `code` as account code.
    ///
    /// `vm.etch` reads any `code` prefixed `0xEF01` as an EIP-7702 delegation
    /// designator and accepts it only when it is exactly 23 bytes long with a
    /// zero version byte at index 2. Every other `code`, including the `0xEF00`
    /// EOF prefix and a bare `0xEF`, is accepted as legacy bytecode.
    //forge-lint: disable-next-line(mixed-case-function)
    function etchAcceptsEIP7702(bytes memory code) internal pure returns (bool) {
        if (code.length >= 2 && code[0] == 0xEF && code[1] == 0x01) {
            return code.length == 23 && code[2] == 0x00;
        }
        return true;
    }

    /// Etches `code` at `target`, rejecting the run when `vm.etch` would not
    /// accept `code`. Fuzz-derived bytes reach `vm.etch` through this function
    /// so that a rejected `code` discards the run instead of failing the test.
    function assumeEtch(Vm vm, address target, bytes memory code) internal {
        vm.assume(etchAcceptsEIP7702(code));
        vm.etch(target, code);
    }
}
