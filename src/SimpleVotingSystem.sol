// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SimpleVotingSystem is AccessControl {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        uint found;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    enum WorkflowStatus {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }
    WorkflowStatus public workflowStatus;

    address public owner;
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
 
    uint[] private candidateIds;

    uint public votingStartTime;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can perform this action"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "Only an admin can perform this action"
        );
        _;
    }

    modifier onlyFounder() {
        require(
            hasRole(FOUNDER_ROLE, msg.sender),
            "Only a founder can perform this action"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Owner gets the default admin role
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function addCandidate(string memory _name) public onlyAdmin {
        require(
            workflowStatus == WorkflowStatus.REGISTER_CANDIDATES,
            "Cannot add candidates at this stage"
        );
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0, 0);
        candidateIds.push(candidateId);
    }

    function vote(uint _candidateId) public {
        require(
            workflowStatus == WorkflowStatus.VOTE,
            "Voting is not allowed at this stage"
        );
        require(
            block.timestamp >= votingStartTime + 1 hours,
            "Voting is not open yet"
        );
        require(!voters[msg.sender], "You have already voted");
        require(
            _candidateId > 0 && _candidateId <= candidateIds.length,
            "Invalid candidate ID"
        );

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
    }

    function getTotalVotes(uint _candidateId) public view returns (uint) {
        require(
            _candidateId > 0 && _candidateId <= candidateIds.length,
            "Invalid candidate ID"
        );
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint) {
        return candidateIds.length;
    }

    function getCandidate(
        uint _candidateId
    ) public view returns (Candidate memory) {
        require(
            _candidateId > 0 && _candidateId <= candidateIds.length,
            "Invalid candidate ID"
        );
        return candidates[_candidateId];
    }

    function setWorkflowStatus(WorkflowStatus _status) public onlyAdmin {
        workflowStatus = _status;
        if (_status == WorkflowStatus.VOTE) {
            votingStartTime = block.timestamp;
        }
    }

    function designateWinner() public view returns (Candidate memory) {
        require(
            workflowStatus == WorkflowStatus.COMPLETED,
            "Voting process is not completed yet"
        );
        uint winningVoteCount = 0;
        Candidate memory winner;
        for (uint i = 0; i < candidateIds.length; i++) {
            if (candidates[candidateIds[i]].voteCount > winningVoteCount) {
                winningVoteCount = candidates[candidateIds[i]].voteCount;
                winner = candidates[candidateIds[i]];
            }
        }
        return winner;
    }

    function fundCandidate(uint _candidateId) public payable onlyFounder {
        require(
            _candidateId > 0 && _candidateId <= candidateIds.length,
            "Invalid candidate ID"
        );

        Candidate memory candidate = getCandidate(_candidateId);

        candidate.found += msg.value;
    }
}