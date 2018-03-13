# FalseByte Carbon Voting

FalseByte Carbon Voting demonstrates a simple trustless carbon voting solution.

Work towards the Aragon integration can be found in the `aragon` branch.

The Carbon Voting Project addresses the issues detailed here [Aragon nest proposal](https://github.com/aragon/nest/issues/6). We specifically solve for the current tradeoffs between different token weighted voting systems in relation to the Double Vote attack.

Double Vote Attack: Two colluding parties collectively increase the weight of their vote by making it appear they have more ERC20 tokens than they really do. For example, assume Alice has 10,000 ColoradoCoin, and Bob has 10,000 ColoradoCoin.  During a vote, Alice votes 'yes' and records her balance of 10,000 tokens. She then transfers all of the tokens to Bob with the intent to cheat. Bob also votes 'yes', but with a recorded weight of 20,000 tokens. As a result, they have collectively voted with a total of 30,000 tokens despite having only 20,000 between the pair.

Any token voting implementation must be designed in such a way to prevent this attack.
* Token Locking:
  - Solution: Force users to lock tokens in a contract for duration of voting period
  - Tradeoff: Creates risk for voting system and means users have to give up their tokens for a period of time.
* Snapshot:
  - Solution: Take snapshots of all voter token balances at each block. MiniMe.
  - Tradeoff: Even with optimizations done by MiniMe could have trouble scaling. In the case of there being a lot of voters who are changing their token balances a lot, there would be a lot of data being stored in the MiniMe snapshots. Also transferring MiniMe tokens costs about 2x more than a regular ERC20 token. 
* Carbon Voting:
  - Solution: Voters emit an event which is counted offchain. No locking and no snapshots.
  - Tradeoff: Results can not be used on chain.
  - Aragon has requested implementing Carbon Voting On-chain - this is the goal of the Falsebyte Carbon Voting Project

FalseByte Carbon Voting gets around all of the tradeoffs listed above by implementing carbon voting onchain! Voters still send their votes with recorded token balances, however, they can also run monitoring agents locally that are watching for votes and token transfers. Since voters care about the results of their vote, they are incentivized to run these agents locally. When a token transfer event occurs with one of the recorded voters, a monitoring agent will update the recorded balance with the `changeBalance` method. Let's go back to the example above with Alice and Bob. This way we can see how Alice and Bob aren't able to pull a fast one on the FalseByte voting system. Alice sends her vote with a weight of 10,000 ColoradoCoin, and then transfers all of her tokens to Bob. The other voter's who are using our monitoring agents will be notified of this transfer and then update Alice's balance to 0. Then when Bob makes his vote with a weight of 20, 000 ColoradoCoin. It is the same as if Alice had just kept her tokens.

There is an interesting edge case at the end of the voting period where a voter may try to vote during the final block(s). Since there is a delay for transaction confirmation, we need to account for balances that are not updated in real time. To compensate, we allow for a grace period where new votes are blocked, but balances are still updated. To prevent voter's from changing their balance during the grace period we only allow balances to be decremented during this time. If a voter tries to increase their token balance during the grace period, the voting contract will not record the update.

<p align="center">
  <img src="./diagram.png"/>
</p>

## Installation Instructions

After cloning the repository

cd into the repo

```
cd falsebyte-carbon-voting
npm install
npm install -g truffle
```

Install test net:
```
npm install -g ganache-cli
```

Run your test net:
```
ganache-cli
```

Deploy contracts to test net:
```
truffle migrate --reset
```

# Usage

You can run through an example voting scenario using the cli with these instructions. We will be using truffle exec to run our scripts.

```bash
alias run="truffle exec cli.js"

# Begin by transferring 15000 ColoradoCoin to account 1

run transfer 1 15000

# Send tokens to rest of participants

run transfer 2 20000
run transfer 3 40000

# Start a super important election for 100 blocks
run election 'super important' 100
# This will output an electionID which we will need

# Start up a monitor agent in a separate tab
run monitor *electionID*

# Back in the original tab, lets send a vote
# Account 1 will vote yes (true)
run vote *electionID* true 1

# Account 1 and 2 will attempt to collude together by getting a double vote
# The attack requires account 1 to transfer their tokens to account 2 after voting
run transfer-from 1 2 15000

# Account 2 will now vote with 35000
# Thus the total votes yes LOOKS like it will be 50000
run vote *electionID* true 2

# Account 3 will vote no (false)
run vote *electionID* false 3

# We will skip the waiting period
run skip 120

# We can now get the results, and see that the monitoring agent actually updated the recorded balance on the ElectionSystem contract
run results *electionID*

# If all went well, the final tally should be yes: 35000 and no: 40000
```

The above list of commands are describing what a voting scenario (like the one above with Alice and Bob) would look like using our system. The final result is equivalent to a result where account1 never transfered tokens to account2. 
