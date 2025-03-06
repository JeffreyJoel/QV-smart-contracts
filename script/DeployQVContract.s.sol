// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {QVContract} from "../src/QV.sol";
import {QVToken} from "../src/QVToken.sol";


contract DeployQVContract is Script {
    function run() public returns (QVToken) {

        vm.startBroadcast();

        QVToken qvT =
            new QVToken(1000000 * 10^18 );

        vm.stopBroadcast();

        return qvT;
    }
}
