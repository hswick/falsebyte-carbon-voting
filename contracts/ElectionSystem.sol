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

    event NewElection(address creator, uint startBlock, uint endBlock, uint tallyBlock, bytes32 electionDescription, bytes32 electionId);
    event NewVote(bytes32 electionId, address voter, uint balance);

    function initializeElection(uint startBlock, uint endBlock, uint tallyBlock, bytes32 electionDescription, ERC20 token) public returns (bytes32) {
        require(tallyBlock > endBlock);
        bytes32 electionId = keccak256(msg.sender, startBlock, endBlock, tallyBlock, electionDescription);
        require(endBlock > startBlock);
        require(tallyBlock > endBlock);
        require(startBlock >= block.number-1);
        Election storage election = elections[electionId];
        require (election.tallyBlockNumber == 0);
        election.votingStartBlockNumber = startBlock;
        election.votingEndBlockNumber = endBlock;
        election.tallyBlockNumber = tallyBlock;
        election.description = electionDescription;
        election.token = token;
        NewElection(msg.sender, startBlock, endBlock, tallyBlock, electionDescription, electionId);
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
        if (vote) {
            el.yesVoteTotal += balance;
        }
        else {
            el.noVoteTotal += balance;
        }
        NewVote(electionId, msg.sender, balance);
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