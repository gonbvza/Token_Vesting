// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/aggregator.sol";

contract HelperConfig is Script {
    networkConfig public activeConfig;

    struct networkConfig {
        address priceFeedContract;
    }

    constructor() {
        if (block.chainid == 97) {
            activeConfig = sepoliaChain();
        } else {
            activeConfig = anvilChain();
        }
    }

    function sepoliaChain() public pure returns (networkConfig memory) {
        networkConfig memory netConf = networkConfig({
            priceFeedContract: 0x1A26d803C2e796601794f8C5609549643832702C
        });
        return netConf;
    }

    function anvilChain() public returns (networkConfig memory) {
        if (activeConfig.priceFeedContract != address(0)) {
            return activeConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator priceFeed = new MockV3Aggregator(8, 565e8);
        vm.stopBroadcast();

        networkConfig memory netConf = networkConfig({
            priceFeedContract: address(priceFeed)
        });

        return netConf;
    }
}
