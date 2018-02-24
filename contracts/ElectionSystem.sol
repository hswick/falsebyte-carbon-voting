pragma solidity ^0.4.17;

import './erc20.sol';


contract ElectionSystem {
    
    struct Vote {
	    // address voter;
	    uint balance;
	    bool vote;
    }

    struct Election {
        mapping(address => Vote) votes;
        uint votingStartBlockNumber;
        uint votingEndBlockNumber;
        uint tallyBlockNumber;
        
        uint yesVoteTotal;
        uint noVoteTotal;
        ERC20 token;
        
    }

    mapping(bytes32 => Election) elections;
    
    event StartVote(uint256 indexed voteId);
    event CastVote(uint256 indexed voteId, address indexed voter, bool supports, uint256 stake);

    event NewElection(address creator, uint startBlock, uint endBlock, uint tallyBlock, uint electionId, ERC20 token);
    
    uint uniq;

    function initializeElection(uint startBlock, uint endBlock, uint tallyBlock, bytes electionDescription, address _token) public returns (bytes32) {
        bytes32 electionId = keccak256(msg.sender, startBlock, endBlock, tallyBlock, electionDescription, uniq);
        uniq++;
        require(endBlock > startBlock);
        require(tallyBlock > endBlock);
        require(startBlock >= block.number-1);
        Election storage election = elections[electionId];
        require (election.tallyBlockNumber == 0);
        election.votingStartBlockNumber = startBlock;
        election.votingEndBlockNumber = endBlock;
        election.tallyBlockNumber = tallyBlock;
        election.token = ERC20(_token);
        StartVote(uint(electionId));
        NewElection(msg.sender, startBlock, endBlock, tallyBlock, uint(electionId), ERC20(_token));
        return electionId;
    }

    function sendVote(bytes32 electionId, bool vote) public {
        Election storage el = elections[electionId];
        require(el.votingStartBlockNumber <= block.number);
        require(el.votingEndBlockNumber >= block.number);
        require(el.votes[msg.sender].balance == 0);
        uint256 balance = el.token.balanceOf(msg.sender);
        require(balance > 0);
        el.votes[msg.sender] = Vote(balance, vote);

        if (vote) 
            el.yesVoteTotal += balance;
        else 
            el.noVoteTotal += balance;

        CastVote(uint(electionId), msg.sender, vote, balance);
    }
    
    // should voter be able to change the vote

    function adjustVoteAccordingToDelta(bytes32 electionId, address voter) internal {
        Election storage el = elections[electionId];
        bool vote = el.votes[voter].vote;
        uint oldBalance = el.votes[voter].balance;
        uint newBalance = el.token.balanceOf(voter);
        require(oldBalance != newBalance);

        if (newBalance > oldBalance) {
            if (block.number < el.votingEndBlockNumber) {
                if (vote) 
                    el.yesVoteTotal += (newBalance - oldBalance);
                else 
                    el.noVoteTotal += (newBalance - oldBalance);
            }
        } else {
            if (vote) 
                el.yesVoteTotal -= (oldBalance - newBalance);
            else 
                el.noVoteTotal -= (oldBalance - newBalance);
        }
        el.votes[voter].balance = newBalance;
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