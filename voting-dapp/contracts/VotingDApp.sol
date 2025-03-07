// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingDApp {
    struct Voter {
        string nationalId;
        string name;
        bool isRegistered;
        bool hasVoted;
        uint votedTo;
    }

    struct Candidate {
        uint candidateId;
        string name;
        address candidateAddress;
        string party;
        uint voteCount;
    }

    address public admin;
    bool public votingOpen;
    uint public totalVoters;
    mapping(address => Voter) public voters;
    mapping(uint => Candidate) public candidates;
    address[] public voterList;
    uint[] public candidateIds;
    
    // New mapping to check if a national ID is already registered
    mapping(string => bool) public registeredNationalIDs;

    event VotingEnded(uint winnerId, string winnerName);
    event VoterRegistered(address voterAddress, string nationalId, string name);
    event CandidateRegistered(uint candidateId, string name, address candidateAddress, string party);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

     // Define admin-specific logic
    function isAdmin(address user) public view returns (bool) {
        return user == admin;
    }

    function changeAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "New admin address cannot be zero");
        admin = newAdmin;
    }


    // Self-registration for voters, allowed anytime
    function registerVoter(string memory _nationalId, string memory _name) public {
        // Check if the voter is already registered using national ID or address
        require(!voters[msg.sender].isRegistered, "Voter is already registered");
        require(!registeredNationalIDs[_nationalId], "National ID is already registered");
        require(bytes(_nationalId).length > 0, "National ID cannot be empty");
        require(bytes(_name).length > 0, "Voter name cannot be empty");

        // Register the voter
        voters[msg.sender] = Voter({
            nationalId: _nationalId,
            name: _name,
            isRegistered: true,
            hasVoted: false,
            votedTo: 0
        });

        // Mark the national ID as registered
        registeredNationalIDs[_nationalId] = true;
        
        voterList.push(msg.sender);
        totalVoters++;

        emit VoterRegistered(msg.sender, _nationalId, _name);
    }

    // Candidate registration, allowed only before voting starts
    function registerCandidate(string memory _name, address _candidateAddress, string memory _party) public onlyAdmin {
        require(!votingOpen, "Cannot register candidates during voting period");
        uint candidateId = candidateIds.length + 1;
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        require(bytes(_party).length > 0, "Party name cannot be empty");
        require(_candidateAddress != address(0), "Invalid candidate address");

        candidates[candidateId] = Candidate({
            candidateId: candidateId,
            name: _name,
            candidateAddress: _candidateAddress,
            party: _party,
            voteCount: 0
        });
        candidateIds.push(candidateId);

        // Automatically register candidate as a voter if not already registered
        if (!voters[_candidateAddress].isRegistered) {
            voters[_candidateAddress] = Voter({
                nationalId: "",
                name: _name,
                isRegistered: true,
                hasVoted: false,
                votedTo: 0
            });
            voterList.push(_candidateAddress);
            totalVoters++;
        }

        emit CandidateRegistered(candidateId, _name, _candidateAddress, _party);
    }

    function startVoting() public onlyAdmin {
        require(candidateIds.length >= 2, "There must be at least two candidates to start voting");
        votingOpen = true;
    }

    function endVoting() public onlyAdmin {
        votingOpen = false;
        declareWinner();
    }

    function vote(uint _candidateId) public {
        require(votingOpen, "Voting is not open");
        require(voters[msg.sender].isRegistered, "You are not a registered voter");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        require(candidates[_candidateId].candidateId != 0, "Candidate does not exist");

        voters[msg.sender].hasVoted = true;
        candidates[_candidateId].voteCount++;
    }

    function getCandidates() public view returns (uint[] memory, string[] memory, string[] memory) {
        uint[] memory ids = new uint[](candidateIds.length);
        string[] memory names = new string[](candidateIds.length);
        string[] memory parties = new string[](candidateIds.length);

        for (uint i = 0; i < candidateIds.length; i++) {
            ids[i] = candidates[candidateIds[i]].candidateId;
            names[i] = candidates[candidateIds[i]].name;
            parties[i] = candidates[candidateIds[i]].party;
        }

        return (ids, names, parties);
    }

    function declareWinner() internal {
        uint highestVotes = 0;
        uint[] memory topCandidates = new uint[](candidateIds.length); // Fixed-size array for temporary storage
        uint count = 0;

        // Identify top candidates
        for (uint i = 0; i < candidateIds.length; i++) {
            if (candidates[candidateIds[i]].voteCount > highestVotes) {
                highestVotes = candidates[candidateIds[i]].voteCount;
                count = 1;
                topCandidates[0] = candidateIds[i];
            } else if (candidates[candidateIds[i]].voteCount == highestVotes) {
                topCandidates[count] = candidateIds[i];
                count++;
            }
        }

        uint winnerId;
        if (count > 1) {
            // Randomly select a winner in case of a tie
            uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % count;
            winnerId = topCandidates[randomIndex];
        } else {
            winnerId = topCandidates[0];
        }

        emit VotingEnded(winnerId, candidates[winnerId].name);
    }
}