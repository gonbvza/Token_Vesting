// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {ImULL} from "../src/imull.sol"; // adjust path if needed

contract DeployImULL is Script {
    function run() external returns (ImULL) {
        vm.startBroadcast();

        ImULL token = new ImULL();

        vm.stopBroadcast();

        return token;
    }
}

