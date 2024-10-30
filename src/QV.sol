// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Quadratic Voting Contract
/// @author Jeffrey Owoloko
/// @notice This contract allows users to create proposals and vote on them using QV tokens.
/// @dev This contract is designed to be used with the QVToken contract.

contract QVContract {

    /// @notice A struct that represents a proposal.
    /// @dev This struct is used to store the details of a proposal.
    struct Proposal {
        string description;
        uint256 votesReceived;
        bool active;
        mapping(address => uint256) voterCredits;
        uint256 totalVotes;
        uint256 votingStart;
        uint256 votingEnd;
        address creator;
    }

    /// @notice A struct that represents a vote.
    /// @dev This struct is used to store the details of a vote.
    struct Vote {
        uint256 proposalId;
        uint256 credits;
        uint256 timestamp;
    }

    /// State Variables ///
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Vote[]) public userVoteHistory;
    uint256 public baseCreditsPerToken;
    address public qvToken;
    address public owner;
    uint256 public proposalCount;

    /// Events ///
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description);
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint256 credits, uint256 cost);
    event VotingPeriodSet(uint256 start, uint256 end);


    constructor(address _qvToken) {
        qvToken = _qvToken;
        owner = msg.sender;
    }

    /// @notice Creates a new proposal.
    /// @param _description The description of the proposal.
    /// @param _votingStart The start time of the voting period.
    /// @param _votingEnd The end time of the voting period.
    function createProposal(string memory _description, uint256 _votingStart, uint256 _votingEnd) external {
       uint256 proposalId = proposalCount++;
       Proposal storage newProposal = proposals[proposalId];
       newProposal.description = _description;
       newProposal.active = true;
       newProposal.votingStart = _votingStart;
       newProposal.votingEnd = _votingEnd;
       newProposal.creator = msg.sender;
       emit ProposalCreated(proposalId, msg.sender,_description);
    }
}
