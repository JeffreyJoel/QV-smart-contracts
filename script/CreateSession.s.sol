// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {QVContract} from "../src/QV.sol";

interface IQContract {
    function registerVoter(string memory _email) external;
    function createVotingSession(
        string memory _name,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _creditsPerVoter
    ) external;

    function addVoterToSession(uint256 _sessionId, address _voter) external;

    function addProposalToSession(uint256 _sessionId, string memory _description) external;

    function castVote(uint256 _sessionId, uint256 _proposalId, uint256 _credits) external;
}

contract CreateVotingSession is Script {
    address qvAddress = address(0x786333fFf4535F1169786d42F7e007abFD85Bd20);

    function run() public {
        vm.startBroadcast();

        // IQContract(qvAddress).createVotingSession(
        //     "Session 1", "Description 1", block.timestamp + 1000, block.timestamp + 10000, 100
        // );

        // IQContract(qvAddress).registerVoter("jeffowoloko@gmail.com");
        IQContract(qvAddress).addVoterToSession(2, msg.sender);
        // IQContract(qvAddress).addProposalToSession(0, "Proposal 1");

        vm.stopBroadcast();
    }
}
