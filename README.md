# FalseByte Carbon Voting

This code base demonstrates a simple trustless carbon voting solution.

If you want to see the repo with work towards Aragon integration check out the `aragon` branch

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