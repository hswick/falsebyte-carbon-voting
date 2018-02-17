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
        
        int yesVoteTotal;
        int noVoteTotal;
        bytes32 description;
        ERC20 token;
        
    }

    mapping(bytes32 => Election) elections;

    event NewElection(address creator, uint startBlock, uint endBlock, uint tallyBlock, bytes32 description);

    function initializeElection(uint startBlock, uint endBlock, uint tallyBlock, bytes32 electionDescription, address token) public returns (bytes32) {
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
        election.token = ERC20(token);
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
        if (vote) el.yesVoteTotal += int(balance);
        else el.noVoteTotal += int(balance);
    }

    // should voter be able to change the vote

    function adjustVoteAccordingToDelta(bytes32 id, address voterAddress) internal {
        Election storage el = elections[id];
        bool vote = el.votes[voterAddress].vote;
        uint oldBalance = el.votes[voterAddress].balance;
        uint newBalance = el.token.balanceOf(voterAddress);
        require(oldBalance != newBalance);
        int delta = int(newBalance) - int(oldBalance);
        // Adjust vote according to delta sign and vote
        if (vote) {
            el.yesVoteTotal += delta;
            el.noVoteTotal -= delta;
        }
        else {
            el.yesVoteTotal -= delta;
            el.noVoteTotal += delta;
        }
        el.votes[voterAddress].balance = newBalance;
    }

    function changeBalance(bytes32 id, address a1, address a2) public {
        Election storage el = elections[id];
        uint balance1 = el.votes[a1].balance;
        uint newBalance1 = el.token.balanceOf(a1);
        uint balance2 = el.votes[a2].balance;
        uint newBalance2 = el.token.balanceOf(a2);
        if (balance1 != newBalance1 && balance1 > 0) adjustVoteAccordingToDelta(id, a1);
        if (balance2 != newBalance2 && balance2 > 0) adjustVoteAccordingToDelta(id, a2);
    }

}

