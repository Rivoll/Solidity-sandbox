// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {RockPapperScissors} from "../src/RockPapperScissors.sol";

contract DeployRockPapperScissors is Script {
    function run() external returns (RockPapperScissors) {
        vm.startBroadcast();
        RockPapperScissors game = new RockPapperScissors();
        vm.stopBroadcast();
        return (game);
    }
}
