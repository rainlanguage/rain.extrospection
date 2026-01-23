// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {Vm} from "forge-std/StdCheats.sol";

library LibExtrospectTestProd {
    uint256 constant PROD_TEST_BLOCK_NUMBER_ARBITRUM = 424447965;

    function createSelectForkArbitrum(Vm vm) internal {
        vm.createSelectFork(vm.envString("RPC_URL_ARBITRUM_FORK"), PROD_TEST_BLOCK_NUMBER_ARBITRUM);
    }
}
