const ElectionSystem = artifacts.require('./ElectionSystem.sol')
const ColoradoCoin = artifacts.require('./ColoradoCoin.sol')
const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"))

describe('ElectionSystem', async function () {
  this.timeout(120000)

  let electionSystem, accounts, electionId

  async function timeout(milliseconds) {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        resolve()
      }, milliseconds)
    })
  }

  before(async () => {
    electionSystem = await ElectionSystem.new()
    coloradoCoin = await ColoradoCoin.new()

    accounts = await web3.eth.getAccounts()

    //send colorado coins to accounts
    await coloradoCoin.transfer(accounts[1], 10000, {from: accounts[0]})
    await coloradoCoin.transfer(accounts[2], 20000, {from: accounts[0]})
  })

  context('Test election system functionality', () => {

    it('initializes new election', async () => {
      const blockNumber = await web3.eth.getBlockNumber()
      let tx = await electionSystem.initializeElection(blockNumber, blockNumber+100, blockNumber+120, 'eth denver hackers voting', coloradoCoin.address, {from: accounts[0]});

      const result = tx.logs[1].args
      
      // console.log(tx.logs)

      electionId = result.electionId

      //Doesn't work yet, must be an encoding issue
      // assert.equal(electionId, web3.utils.keccak256(
      //   result.creator,
      //   result.startBlock.toNumber(),
      //   result.endBlock.toNumber(),
      //   result.tallyBlock.toNumber(),
      //   result.electionDescription
      // ))
    })

    it('sends a vote', async () => {
      // console.log("id", electionId)

      const tx = await electionSystem.sendVote(electionId, true, {from: accounts[1]});

      const result = tx.logs[0].args
      assert.equal(result.voteId.toString(), electionId.toString())
      assert.equal(result.voter, accounts[1].toLowerCase())
      assert.equal(result.stake.toNumber(), 10000)

    })

    it('sends another vote', async () => {

      let tx = await electionSystem.sendVote(electionId, false, {from: accounts[2]});

      const result = tx.logs[0].args
      assert.equal(result.voteId.toString(), electionId.toString())
      assert.equal(result.voter, accounts[2].toLowerCase())
      assert.equal(result.stake.toNumber(), 20000)

    })
  })
})