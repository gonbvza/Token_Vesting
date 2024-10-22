// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {PreSale} from "../src/tokenPreSale.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ImULL} from "../src/imull.sol";

contract DeployPreSale is Script {
    function run(ImULL token) external returns (PreSale) {
        HelperConfig helperConfig = new HelperConfig();
        address priceFeedContract = helperConfig.activeConfig();

        vm.startBroadcast();
        PreSale preSale = new PreSale(token, priceFeedContract);
        vm.stopBroadcast();
        return preSale;
    }
}
