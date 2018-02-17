pragma solidity ^0.4.19;

import './erc20.sol';

contract ElectionSystem {
    struct Vote {
	    address voter;
	    uint balance;
	    uint vote;
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
    
}



