pragma solidity ^0.4.17;

import './erc20.sol';

contract CommitElectionSystem {
    
    uint constant TALLY_PERIOD = 20; // reveal and tally the votes
    uint constant REVEAL_PERIOD = 5; // cooldown before reveal
    
    struct Vote {
	    // address voter;
	    uint balance;
	    bytes32 vote;
    }

    struct Election {
        mapping(address => Vote) votes;
        uint votingStartBlockNumber;
        uint votingEndBlockNumber;
        uint revealBlockNumber;
        uint tallyBlockNumber;
        
        uint yesVoteTotal;
        uint noVoteTotal;
        ERC20 token;
        
        string metadata;
        bytes executionScript;
        bool executed;
        uint256 minAcceptQuorumPct;
        uint startDate;
        
    }

    mapping(bytes32 => Election) elections;
    
    event StartVote(uint256 indexed voteId);
    event CastVote(uint256 indexed voteId, address indexed voter, bool supports, uint256 stake);
    event CommitVote(uint256 indexed voteId, address indexed voter, bytes32 supports, uint256 stake);

    event NewElection(address creator, uint startBlock, uint endBlock, uint tallyBlock, uint electionId, ERC20 token);
    
    uint uniq;

    function initializeElection(uint startBlock, uint endBlock, uint revealBlock, uint tallyBlock, bytes electionDescription, ERC20 _token) public returns (bytes32) {
        bytes32 electionId = keccak256(msg.sender, startBlock, endBlock, revealBlock, tallyBlock, electionDescription, uniq);
        uniq++;
        require(endBlock > startBlock);
        require(revealBlock > endBlock);
        require(tallyBlock > revealBlock);
        require(startBlock >= block.number-1);
        Election storage election = elections[electionId];
        require (election.tallyBlockNumber == 0);
        election.votingStartBlockNumber = startBlock;
        election.votingEndBlockNumber = endBlock;
        election.tallyBlockNumber = tallyBlock;
        election.revealBlockNumber = revealBlock;
        election.token = ERC20(_token);
        StartVote(uint(electionId));
        NewElection(msg.sender, startBlock, endBlock, tallyBlock, uint(electionId), _token);
        return electionId;
    }

    function sendVote(bytes32 electionId, bytes32 vote) public {
        Election storage el = elections[electionId];
        require(el.votingStartBlockNumber <= block.number);
        require(el.votingEndBlockNumber >= block.number);
        require(el.votes[msg.sender].balance == 0);
        uint256 balance = el.token.balanceOf(msg.sender);
        // uint256 balance = 0;
        require(balance > 0);
        el.votes[msg.sender] = Vote(balance, vote);
        CommitVote(uint(electionId), msg.sender, vote, balance);
    }
    
    function revealVote(uint electionId, bool vote, bytes32 secret) public {
        Election storage el = elections[bytes32(electionId)];
        require(el.revealBlockNumber <= block.number);
        require(el.tallyBlockNumber >= block.number);
        require(el.votes[msg.sender].vote == keccak256(vote, secret));
        
        uint balance = el.votes[msg.sender].balance;
        if (vote) 
            el.yesVoteTotal += balance;
        else 
            el.noVoteTotal += balance;
        CastVote(uint(electionId), msg.sender, vote, balance);
    }

    function checkVote(bool vote, bytes32 secret) public returns (bytes32) {
        return keccak256(vote, secret);
    }

    function slashVote(uint electionId, address voter, bool vote, bytes32 secret) public {
        Election storage el = elections[bytes32(electionId)];
        require(el.revealBlockNumber >= block.number);
        require(el.votingStartBlockNumber <= block.number);
        require(el.votes[voter].vote == keccak256(vote, secret));
        
        el.votes[voter].balance = 0;
    }
    
    // should voter be able to change the vote

    function adjustVoteAccordingToDelta(bytes32 electionId, address voter) internal {
        Election storage el = elections[electionId];
        uint oldBalance = el.votes[voter].balance;
        uint newBalance = el.token.balanceOf(voter);
        require(oldBalance != newBalance);

        if (newBalance > oldBalance) {
            if (block.number < el.votingEndBlockNumber) {
                el.votes[voter].balance = newBalance;
            }
        }
        else {
            el.votes[voter].balance = newBalance;
        }
    }
    
    function changeBalance(bytes32 electionId, address voter) public {
        Election storage el = elections[electionId];
        require(block.number < el.tallyBlockNumber);
        uint balance = el.votes[voter].balance;
        uint newBalance = el.token.balanceOf(voter);
        if (balance != newBalance && balance > 0) 
            adjustVoteAccordingToDelta(electionId, voter);
    }

    function getElectionResults(bytes32 electionId) public view returns(uint finalYesVoteTotal, uint finalNoVoteTotal) {
        Election storage el = elections[electionId];
        require(block.number > el.tallyBlockNumber);
        finalYesVoteTotal = el.yesVoteTotal;
        finalNoVoteTotal = el.noVoteTotal;
    }
}

