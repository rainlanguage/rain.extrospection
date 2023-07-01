// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Script.sol";
import "src/concrete/CloneFactory.sol";

/// @title DeployExtrospection
/// @notice A script that deploys Extrospection. This is intended to be run on
/// every commit by CI to a testnet such as mumbai, then cross chain deployed to
/// whatever mainnet is required, by users.
contract DeployExtrospection is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        vm.startBroadcast(deployerPrivateKey);
        Extrospection extrospection = new Extrospection();
        (extrospection);
        vm.stopBroadcast();
    }
}
