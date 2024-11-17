// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Quadratic Voting Contract
/// @author Jeffrey Owoloko
/// @notice This contract allows admins to create voting sessions with proposals, and allows users to vote on these proposals using QV tokens.
/// @dev This contract is designed to be used with the QVToken contract.

contract QVContract {
    struct VotingSession {
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 creditsPerVoter;
        bool active;
        mapping(uint256 => Proposal) proposals;
        uint256 proposalCount;
        address creator;
        mapping(address => Voter) voters;
    }

    /// @notice A struct that represents a proposal.
    /// @dev This struct is used to store the details of a proposal.
    struct Proposal {
        string description;
        uint256 voteCount;
    }

    struct Voter {
        string email;
        mapping(uint256 => uint256) creditBalance; // mapping of sessionId to credits
        mapping(uint256 => mapping(uint256 => uint256)) votesPerProposal; // mapping of sessionId to proposalId to votes
    }

    /// @notice A struct that represents a vote.
    /// @dev This struct is used to store the details of a vote.
    struct Vote {
        uint256 proposalId;
        uint256 credits;
        uint256 timestamp;
    }

    /// State Variables ///
    mapping(uint256 => VotingSession) public votingSessions;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Vote[]) public userVoteHistory;
    mapping(address => Voter) public voters;
    uint256 public sessionCount;
    uint256 public baseCredits = 100;
    address public qvToken;
    address public owner;

    /// Events ///
    event SessionCreated(uint256 indexed sessionId, string name, address creator);
    event ProposalAdded(uint256 indexed proposalId, uint256 indexed sessionId, string description);
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint256 credits, uint256 cost);
    event VotingPeriodSet(uint256 start, uint256 end);

    constructor() {
        // qvToken = _qvToken;
        owner = msg.sender;
    }

    function registerVoter(string memory _email) external {
        voters[msg.sender].email = _email;
    }

    function createVotingSession(
        string memory _name,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _creditsPerVoter
    ) external {
        require(_startTime > block.timestamp, "Start time must be in the future!");
        uint256 sessionId = sessionCount++;
        VotingSession storage newSession = votingSessions[sessionId];
        newSession.name = _name;
        newSession.description = _description;
        newSession.startTime = _startTime;
        newSession.endTime = _endTime;
        newSession.creditsPerVoter = _creditsPerVoter;
        newSession.creator = msg.sender;

        if (_startTime <= block.timestamp) {
            newSession.active = true;
        }

        emit SessionCreated(sessionId, _name, msg.sender);
    }

    function addVoterToSession(uint256 _sessionId, address _voter) external {
        require(votingSessions[_sessionId].active, "Session is inactive!");
        votingSessions[_sessionId].voters[_voter].email = voters[msg.sender].email;
        votingSessions[_sessionId].voters[_voter].creditBalance[_sessionId] = baseCredits;
    }

    function addProposalToSession(uint256 _sessionId, string memory _description) external {
        require(votingSessions[_sessionId].active, "Session is inactive!");
        uint256 proposalId = votingSessions[_sessionId].proposalCount++;
        Proposal storage newProposal = votingSessions[_sessionId].proposals[proposalId];
        newProposal.description = _description;
        emit ProposalAdded(proposalId, _sessionId, _description);
    }

    function castVote(uint256 _sessionId, uint256 _proposalId, uint256 _credits) external {
        require(votingSessions[_sessionId].active, "Session is inactive!");
        require(
            votingSessions[_sessionId].voters[msg.sender].creditBalance[_sessionId] >= _credits, "Insufficient credits!"
        );
        uint256 vote = _sqrt(_credits);
        votingSessions[_sessionId].voters[msg.sender].votesPerProposal[_sessionId][_proposalId] += vote;
        votingSessions[_sessionId].voters[msg.sender].creditBalance[_sessionId] -= _credits;
        emit VoteCast(msg.sender, _proposalId, vote, _credits);
    }

    /// Internal functions ///
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0 (default value)
    }
}
