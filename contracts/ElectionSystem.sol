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

    event NewElection(bytes32 id, address creator, uint startBlock, uint endBlock, uint tallyBlock, bytes32 description, address token);

    function initializeElection(uint startBlock, uint endBlock, uint tallyBlock, bytes32 electionDescription, address token) public returns (bytes32) {
        bytes32 id = keccak256(msg.sender, startBlock, endBlock, tallyBlock, electionDescription, token);
        require(endBlock > startBlock);
        require(tallyBlock > endBlock);
        require(startBlock > block.number);
        Election storage election = elections[id];
        require (election.tallyBlockNumber == 0);
        election.votingStartBlockNumber = startBlock;
        election.votingEndBlockNumber = endBlock;
        election.tallyBlockNumber = tallyBlock;
        election.description = electionDescription;
        election.token = ERC20(token);
        NewElection(id, msg.sender, startBlock, endBlock, tallyBlock, electionDescription, token);
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

    function adjustVoteAccordingToDelta(bytes32 id, address voterAddress) internal {
        Election storage el = elections[id];
        bool vote = el.votes[voterAddress].vote;
        uint oldBalance = el.votes[voterAddress].balance;
        uint newBalance = el.token.balanceOf(voterAddress);
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
        el.votes[voterAddress].balance = newBalance;
    }
    
    // 

    function changeBalance(bytes32 id, address a1) public {
        Election storage el = elections[id];
        uint balance = el.votes[a1].balance;
        uint newBalance = el.token.balanceOf(a1);
        if (balance != newBalance && balance > 0) adjustVoteAccordingToDelta(id, a1);
    }

}

