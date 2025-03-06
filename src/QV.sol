// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title Room-Based Quadratic Voting
/// @author Jeffrey Owoloko
/// @notice This contract allows admins to create rooms with entry keys and voting sessions with proposals
/// @dev Implements secure room access control using hashed entry keys

contract QVContract {
    struct Room {
        string name;
        string description;
        bytes32 entryKeyHash; // Stored hash of the entry key
        bool active;
        address creator;
        mapping(uint256 => VotingSession) sessions;
        uint256 sessionCount;
        mapping(address => bool) authorizedVoters;
        uint256 createdAt;
        uint256 participantCount;
    }

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
        mapping(address => mapping(uint256 => uint256)) votesPerProposal; // voter => proposalId => votes
        mapping(address => uint256) voterCredits; // Credits per voter in this session
    }

    struct Proposal {
        string title;
        string description;
        uint256 voteCount;
    }

    struct Voter {
        string matNumber;
        bool isRegistered;
    }

    struct Vote {
        uint256 proposalId;
        uint256 credits;
        uint256 timestamp;
    }

    /// State Variables ///
    mapping(uint256 => Room) public rooms;
    mapping(address => Voter) public voters;
    mapping(address => Vote[]) public userVoteHistory;
    mapping(uint256 => uint256[]) public sessionIdsByRoom;
    uint256[] public roomIds;
    uint256 public roomCount;
    uint8 public baseCredits = 100;
    address public owner;

    /// Events ///
    event RoomCreated(uint256 indexed roomId, string name, address creator);
    event SessionCreated(
        uint256 indexed roomId,
        uint256 indexed sessionId,
        string name,
        address creator
    );
    event ProposalAdded(
        uint256 indexed sessionId,
        uint256 indexed proposalId,
        string description
    );
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        uint256 credits,
        uint256 cost
    );
    event VoterRegistered(address indexed voter, string matNumber);
    event RoomAccessGranted(uint256 indexed roomId, address indexed voter);

    // Errors
    error InvalidEntryKey();
    error NotAuthorized();
    error RoomNotActive();
    error SessionNotActive();
    error InsufficientCredits();
    error VoterNotRegistered();
    error SessionNotInProgress();

    constructor() {
        owner = msg.sender;
    }

    /// @notice Creates a new room with an entry key
    /// @dev The entry key is hashed before storage
    function createRoom(
        string memory _name,
        string memory _description,
        string memory _entryKey
    ) external {
        uint256 roomId = roomCount += 1;
        Room storage newRoom = rooms[roomId];
        newRoom.name = _name;
        newRoom.description = _description;
        newRoom.entryKeyHash = keccak256(abi.encodePacked(_entryKey));
        newRoom.active = true;
        newRoom.creator = msg.sender;
        newRoom.createdAt = block.timestamp;
        // Auto-authorize room creator
        newRoom.authorizedVoters[msg.sender] = true;
        roomIds.push(roomId);

        emit RoomCreated(roomId, _name, msg.sender);
    }

    /// @notice Register a voter with their matNumber
    function registerVoter(string memory _matNumber) external {
        voters[msg.sender].matNumber = _matNumber;
        voters[msg.sender].isRegistered = true;
        emit VoterRegistered(msg.sender, _matNumber);
    }

    /// @notice Join a room using an entry key
    function joinRoom(uint256 _roomId, string memory _entryKey) external {
        if (!voters[msg.sender].isRegistered) revert VoterNotRegistered();
        if (!rooms[_roomId].active) revert RoomNotActive();

        bytes32 providedKeyHash = keccak256(abi.encodePacked(_entryKey));
        if (providedKeyHash != rooms[_roomId].entryKeyHash)
            revert InvalidEntryKey();

        rooms[_roomId].authorizedVoters[msg.sender] = true;
        rooms[_roomId].participantCount += 1;

        emit RoomAccessGranted(_roomId, msg.sender);
    }

    /// @notice Check if a user has access to a room
    function hasRoomAccess(
        uint256 _roomId,
        address _user
    ) public view returns (bool) {
        return rooms[_roomId].authorizedVoters[_user];
    }

    function createVotingSession(
        uint256 _roomId,
        string memory _name,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _creditsPerVoter,
        Proposal[] memory _proposals
    ) external {
        if (!rooms[_roomId].active) revert RoomNotActive();
        if (!rooms[_roomId].authorizedVoters[msg.sender])
            revert NotAuthorized();
        require(
            _startTime > block.timestamp,
            "Start time must be in the future!"
        );
        require(_endTime > _startTime, "End time must be after start time!");
        require(_proposals.length > 0, "At least one proposal is required!");

        uint256 sessionId = rooms[_roomId].sessionCount++;
        VotingSession storage newSession = rooms[_roomId].sessions[sessionId];
        newSession.name = _name;
        newSession.description = _description;
        newSession.startTime = _startTime;
        newSession.endTime = _endTime;
        newSession.creditsPerVoter = _creditsPerVoter;
        newSession.creator = msg.sender;
        newSession.active = true;

        for (uint256 i = 0; i < _proposals.length; i++) {
            uint256 proposalId = newSession.proposalCount++;
            Proposal storage newProposal = newSession.proposals[proposalId];
            newProposal.title = _proposals[i].title;
            newProposal.description = _proposals[i].description;
            emit ProposalAdded(
                sessionId,
                proposalId,
                _proposals[i].description
            );
        }
        sessionIdsByRoom[_roomId].push(sessionId);

        emit SessionCreated(_roomId, sessionId, _name, msg.sender);
    }

    function castVote(
        uint256 _roomId,
        uint256 _sessionId,
        uint256[] memory _proposalIds,
        uint256[] memory _credits
    ) external {
        // Check room and authorization
        if (!rooms[_roomId].active) revert RoomNotActive();
        if (!rooms[_roomId].authorizedVoters[msg.sender])
            revert NotAuthorized();

        VotingSession storage session = rooms[_roomId].sessions[_sessionId];

        // Check session timing
        if (
            block.timestamp < session.startTime ||
            block.timestamp > session.endTime
        ) {
            revert SessionNotInProgress();
        }

        // Initialize credits for first-time voters in this session
        if (session.voterCredits[msg.sender] == 0) {
            session.voterCredits[msg.sender] = baseCredits;
        }

        // Ensure the arrays are of the same length
        require(
            _proposalIds.length == _credits.length,
            "Mismatched proposal IDs and credits"
        );

        // Iterate through the arrays and process each vote
        for (uint256 i = 0; i < _proposalIds.length; i++) {
            uint256 proposalId = _proposalIds[i];
            uint256 credits = _credits[i];

            // Check if the voter has enough credits
            if (session.voterCredits[msg.sender] < credits) {
                revert InsufficientCredits();
            }

            // Calculate the vote weight using the square root of the credits
            uint256 vote = _sqrt(credits);

            // Update the vote count for the proposal
            session.votesPerProposal[msg.sender][proposalId] += vote;
            session.voterCredits[msg.sender] -= credits;
            session.proposals[proposalId].voteCount += vote;

            // Record vote in history
            userVoteHistory[msg.sender].push(
                Vote({
                    proposalId: proposalId,
                    credits: credits,
                    timestamp: block.timestamp
                })
            );

            emit VoteCast(msg.sender, proposalId, vote, credits);
        }
    }

    /// @notice Get remaining credits for a voter in a session
    function getVoterCredits(
        uint256 _roomId,
        uint256 _sessionId,
        address _voter
    ) external view returns (uint256) {
        return rooms[_roomId].sessions[_sessionId].voterCredits[_voter];
    }

    function getRoomDetails(
        uint256 _roomId
    )
        external
        view
        returns (
            string memory name,
            string memory description,
            bool active,
            address creator
        )
    {
        Room storage room = rooms[_roomId];
        return (room.name, room.description, room.active, room.creator);
    }

    /// @notice Get voter details
    function getVoterDetails(
        address _voter
    ) external view returns (string memory matNumber, bool isRegistered) {
        Voter storage voter = voters[_voter];
        return (voter.matNumber, voter.isRegistered);
    }

    /// @notice Get vote history for a user
    function getUserVoteHistory(
        address _user
    ) external view returns (Vote[] memory) {
        return userVoteHistory[_user];
    }

    /// @notice Get all session IDs for a room
    function getSessionIdsForRoom(
        uint256 _roomId
    ) external view returns (uint256[] memory) {
        return sessionIdsByRoom[_roomId];
    }

    /// @notice Get all room IDs
    function getAllRoomIds() external view returns (uint256[] memory) {
        return roomIds;
    }

    /// @notice Get session details
    function getSessionDetails(
        uint256 _roomId,
        uint256 _sessionId
    )
        external
        view
        returns (
            string memory name,
            string memory description,
            uint256 startTime,
            uint256 endTime,
            uint256 creditsPerVoter,
            bool active,
            address creator,
            uint256 proposalCount
        )
    {
        VotingSession storage session = rooms[_roomId].sessions[_sessionId];
        return (
            session.name,
            session.description,
            session.startTime,
            session.endTime,
            session.creditsPerVoter,
            session.active,
            session.creator,
            session.proposalCount
        );
    }

    /// @notice Get proposal details
    function getProposalDetails(
        uint256 _roomId,
        uint256 _sessionId,
        uint256 _proposalId
    )
        external
        view
        returns (
            string memory title,
            string memory description,
            uint256 voteCount
        )
    {
        VotingSession storage session = rooms[_roomId].sessions[_sessionId];
        Proposal storage proposal = session.proposals[_proposalId];
        return (proposal.title, proposal.description, proposal.voteCount);
    }

    /// @notice Get votes cast by a voter for a specific proposal in a session
    function getVoterProposalVotes(
        uint256 _roomId,
        uint256 _sessionId,
        address _voter,
        uint256 _proposalId
    ) external view returns (uint256) {
        require(
            _proposalId < rooms[_roomId].sessions[_sessionId].proposalCount,
            "Invalid proposal ID"
        );

        return
            rooms[_roomId].sessions[_sessionId].votesPerProposal[_voter][
                _proposalId
            ];
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
    }
}
