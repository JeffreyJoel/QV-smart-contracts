// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract QVToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("QV-Platform token", "QVT") {
        _mint(msg.sender, initialSupply);
    }
}