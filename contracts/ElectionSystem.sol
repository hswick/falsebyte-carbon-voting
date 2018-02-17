pragma solidity ^0.4.17;

import './erc20.sol';

import "@aragon/os/contracts/apps/AragonApp.sol";

import "@aragon/os/contracts/common/IForwarder.sol";

import "@aragon/os/contracts/lib/zeppelin/math/SafeMath.sol";
import "@aragon/os/contracts/lib/misc/Migrations.sol";


contract ElectionSystem is IForwarder, AragonApp {

    uint256 constant public PCT_BASE = 10 ** 18;

    bytes32 constant public CREATE_VOTES_ROLE = keccak256("CREATE_VOTES_ROLE");
    bytes32 constant public MODIFY_QUORUM_ROLE = keccak256("MODIFY_QUORUM_ROLE");
    
    uint constant TALLY = 5;
    
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
        
        string metadata;
        bytes executionScript;
        bool executed;
        uint256 minAcceptQuorumPct;
        uint startDate;
        
    }

    mapping(bytes32 => Election) elections;
    
    event StartVote(uint256 indexed voteId);
    event CastVote(uint256 indexed voteId, address indexed voter, bool supports, uint256 stake);
    event ExecuteVote(uint256 indexed voteId);
    event ChangeMinQuorum(uint256 minAcceptQuorumPct);

    ERC20 public token;
    uint256 public supportRequiredPct;
    uint256 public minAcceptQuorumPct;
    uint64 public voteTime;
    
    function initialize(
        ERC20 _token,
        uint256 _supportRequiredPct,
        uint256 _minAcceptQuorumPct,
        uint64 _voteTime
    ) onlyInit external
    {
        initialized();

        require(_supportRequiredPct > 1);
        require(_supportRequiredPct <= PCT_BASE);
        require(_supportRequiredPct >= _minAcceptQuorumPct);

        token = _token;
        supportRequiredPct = _supportRequiredPct;
        minAcceptQuorumPct = _minAcceptQuorumPct;
        voteTime = _voteTime;
    }

    /**
    * @notice Change minimum acceptance quorum to `_minAcceptQuorumPct`
    * @param _minAcceptQuorumPct New acceptance quorum
    */
    function changeMinAcceptQuorumPct(uint256 _minAcceptQuorumPct) authP(MODIFY_QUORUM_ROLE, arr(_minAcceptQuorumPct, minAcceptQuorumPct)) external {
        require(supportRequiredPct >= _minAcceptQuorumPct);
        minAcceptQuorumPct = _minAcceptQuorumPct;

        ChangeMinQuorum(_minAcceptQuorumPct);
    }
    
    function newVote(bytes _executionScript, string _metadata) auth(CREATE_VOTES_ROLE) public returns (uint256 voteId) {
        bytes32 id = initializeElection(block.number, block.number+voteTime, block.number+voteTime+TALLY, 0, token);
        Election storage el = elections[id];
        el.executionScript = _executionScript;
        el.metadata = _metadata;
        
        return uint(id);
    }
    
    // will only be decided after tallying ends
    function vote(uint256 _voteId, bool _supports, bool /* _executesIfDecided */) external {
        // require(canVote(_voteId, msg.sender));
        sendVote(bytes32(_voteId), _supports);
    }

    event NewElection(bytes32 id, address creator, uint startBlock, uint endBlock, uint tallyBlock, bytes32 description, address token);
    
    function initializeElection(uint startBlock, uint endBlock, uint tallyBlock, bytes32 electionDescription, address _token) public returns (bytes32) {
        bytes32 id = keccak256(msg.sender, startBlock, endBlock, tallyBlock, electionDescription, _token);
        require(endBlock > startBlock);
        require(tallyBlock > endBlock);
        require(startBlock > block.number);
        Election storage election = elections[id];
        require (election.tallyBlockNumber == 0);
        election.votingStartBlockNumber = startBlock;
        election.votingEndBlockNumber = endBlock;
        election.tallyBlockNumber = tallyBlock;
        election.description = electionDescription;
        election.minAcceptQuorumPct = minAcceptQuorumPct;
        election.token = ERC20(_token);
        NewElection(id, msg.sender, startBlock, endBlock, tallyBlock, electionDescription, _token);
        StartVote(uint(id));
        return id;
    }
    
    function canVote(uint256 _voteId, address /* _voter */ ) public view returns (bool) {
        Election storage el = elections[bytes32(_voteId)];
        return el.votingStartBlockNumber <= block.number && el.votingEndBlockNumber >= block.number;
    }

    /**
    * @notice Execute the result of vote `_voteId`
    * @param _voteId Id for vote
    */
    function executeVote(uint256 _voteId) external {
        require(canExecute(_voteId));
        _executeVote(_voteId);
    }

    function isForwarder() public pure returns (bool) {
        return true;
    }

    /**
    * @dev IForwarder interface conformance
    * @param _evmScript Start vote with script
    */
    function forward(bytes _evmScript) public {
        require(canForward(msg.sender, _evmScript));
        newVote(_evmScript, "");
    }

    function canForward(address _sender, bytes /* _evmCallScript */) public view returns (bool) {
        return canPerform(_sender, CREATE_VOTES_ROLE, arr());
    }
    
    function canExecute(uint256 _voteId) public view returns (bool) {
        Election storage el = elections[bytes32(_voteId)];
        if (el.executed) return false;
        if (block.number < el.tallyBlockNumber) return false;
        uint totalVoters = el.token.totalSupply();
        uint totalVotes = el.yesVoteTotal + el.noVoteTotal;
        bool hasSupport = _isValuePct(el.yesVoteTotal, totalVotes, supportRequiredPct);
        bool hasMinQuorum = _isValuePct(el.yesVoteTotal, totalVoters, el.minAcceptQuorumPct);
        return hasSupport && hasMinQuorum;
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
        CastVote(uint(electionId), msg.sender, vote, balance);
    }

    function _executeVote(uint256 _voteId) internal {
        Election storage vote = elections[bytes32(_voteId)];

        vote.executed = true;

        bytes memory input = new bytes(0);
        runScript(vote.executionScript, input, new address[](0));

        ExecuteVote(_voteId);
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

    /**
    * @dev Calculates whether `_value` is at least a percent `_pct` over `_total`
    */
    function _isValuePct(uint256 _value, uint256 _total, uint256 _pct) internal pure returns (bool) {
        if (_value == 0 && _total > 0)
            return false;

        uint256 m = _total * _pct;
        uint256 v = m / PCT_BASE;

        // If division is exact, allow same value, otherwise require value to be greater
        return m % PCT_BASE == 0 ? _value >= v : _value > v;
    }

}

