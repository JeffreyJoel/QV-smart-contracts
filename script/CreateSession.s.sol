// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {QVContract} from "../src/QV.sol";
import "forge-std/console.sol";

struct Proposal {
    string title;
    string description;
    uint256 voteCount;
}

interface IQContract {
    function createRoom(
        string memory _name,
        string memory _description,
        string memory _entryKey
    ) external;
    function createVotingSession(
        uint256 _roomId,
        string memory _name,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _creditsPerVoter,
        Proposal[] memory _proposals
    ) external;

    function addVoterToSession(uint256 _sessionId, address _voter) external;

    function addProposalToSession(
        uint256 _sessionId,
        string memory _description
    ) external;

    function castVote(
        uint256 _roomId,
        uint256 _sessionId,
        uint256[] memory _proposalIds,
        uint256[] memory _credits
    ) external;
    function joinRoom(uint256 _roomId, string memory _entryKey) external;
    function registerVoter(string memory _matNumber) external;
}

contract CreateVotingSession is Script {
    address qvAddress = address(0x50139d921E6746C628dB7AbEc73060e8DA70afad);

    function run() public {
        Proposal[] memory proposals = new Proposal[](4);

        proposals[0] = Proposal({
            title: "Buy New Class Equipment",
            description: "Purchase new laboratory equipment for student experiments",
            voteCount: 0
        });

        proposals[1] = Proposal({
            title: "Field Trip Fund",
            description: "Allocate funds for industrial site visits and field trips",
            voteCount: 0
        });

        proposals[2] = Proposal({
            title: "Workshop Series",
            description: "Organize professional development workshops with industry experts",
            voteCount: 0
        });

        proposals[3] = Proposal({
            title: "Research Grant",
            description: "Create a small grant program for undergraduate research projects",
            voteCount: 0
        });
        // uint256[] memory proposalIds = new uint256[](4);
        // proposalIds[0] = 0; // Voting for Proposal 0
        // proposalIds[1] = 2; // Voting for Proposal 2

        // uint256[] memory credits = new uint256[](4);
        // credits[0] = 40; // 40 credits for Proposal 0
        // credits[1] = 60;
        vm.startBroadcast();

        IQContract(qvAddress).createVotingSession(
           1, "Session 2", "Budget allocation for Semester 2", 1739171777, 1739528400, 100, proposals
        );

        // IQContract(qvAddress).castVote(1, 1, proposalIds, credits);
        // console.log(block.timestamp);

        // IQContract(qvAddress).createRoom("CPE-190", "Vote on how to allocate the 2024 session funds", "ENG190");
        // IQContract(qvAddress).addVoterToSession(2, msg.sender);
        // IQContract(qvAddress).addProposalToSession(0, "Proposal 1");
        // IQContract(qvAddress).joinRoom(1, "ENG190");
        // IQContract(qvAddress).registerVoter("ENG1905131");


        vm.stopBroadcast();
    }
}
