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
        bytes32 description;
        ERC20 token;
        
    }

    mapping(bytes32 => Election) elections;

    event NewElection(address creator, uint startBlock, uint endBlock, uint tallyBlock, bytes32 description);

    function initializeElection(uint startBlock, uint endBlock, uint tallyBlock, bytes32 electionDescription, ERC20 token) public returns (bytes32) {
        bytes32 id = keccak256(msg.sender, startBlock, endBlock, tallyBlock, electionDescription);
        require(endBlock > startBlock);
        require(tallyBlock > endBlock);
        require(startBlock > block.number);
        Election storage election = elections[id];
        require (election.tallyBlockNumber == 0);
        election.votingStartBlockNumber = startBlock;
        election.votingEndBlockNumber = endBlock;
        election.tallyBlockNumber = tallyBlock;
        election.description = electionDescription;
        election.token = token;
        return id;
    }

    function sendVote(bytes32 electionId, bool vote) public {
        Election storage el = elections[electionId];
        require(el.votingStartBlockNumber <= block.number);
        require(el.votingEndBlockNumber >= block.number);
        require(el.votes[msg.sender].balance == 0);
        uint balance = el.token.balanceOf(msg.sender);
        require(balance > 0);
        el.votes[msg.sender] = Vote(balance, vote);
        if (vote) el.yesVoteTotal += balance;
        else el.noVoteTotal += balance;
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
                if (vote) el.yesVoteTotal += (newBalance - oldBalance);
                else el.noVoteTotal += (newBalance - oldBalance);
            }
        }
        else {
            if (vote) el.yesVoteTotal -= (oldBalance - newBalance);
            else el.noVoteTotal -= (oldBalance - newBalance);
        }
        el.votes[voter].balance = newBalance;
    }
    
    function changeBalance(bytes32 electionId, address voter) public {
        Election storage el = elections[electionId];
        uint balance = el.votes[voter].balance;
        uint newBalance = el.token.balanceOf(voter);
        if (balance != newBalance && balance > 0) adjustVoteAccordingToDelta(electionId, voter);
    }

}