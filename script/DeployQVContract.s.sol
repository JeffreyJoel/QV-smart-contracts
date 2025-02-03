// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {QVContract} from "../src/QV.sol";

contract DeployQVContract is Script {
    function run() public returns (QVContract) {

        vm.startBroadcast();

        QVContract qv =
            new QVContract();

        vm.stopBroadcast();

        return qv;
    }
}
