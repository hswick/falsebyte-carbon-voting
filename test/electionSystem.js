const ElectionSystem = artifacts.require('./ElectionSystem.sol')
const ColoradoCoin = artifacts.require('./ColoradoCoin.sol')
const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"))
const mineBlocks = require('./helpers/mineBlocks')(web3)
const toHex = require('./helpers/toHex')

describe('ElectionSystem', async function () {
  this.timeout(120000)
  
  let electionSystem, accounts, electionId

  const votingTime = 1000;

  before(async () => {
    coloradoCoin = await ColoradoCoin.at(ColoradoCoin.address)
    electionSystem = await ElectionSystem.at(ElectionSystem.address)
    accounts = await web3.eth.getAccounts()

    //send colorado coins to accounts
    if((await coloradoCoin.balanceOf.call(accounts[1])).toNumber() == 0) {
      await coloradoCoin.transfer(accounts[1], 10000, { from: accounts[0] })
    }
    if((await coloradoCoin.balanceOf.call(accounts[2])).toNumber() == 0) {
      await coloradoCoin.transfer(accounts[2], 20000, { from: accounts[0] })
    }
    if((await coloradoCoin.balanceOf.call(accounts[4])).toNumber() == 0) {
      await coloradoCoin.transfer(accounts[4], 20000, { from: accounts[0] })
    }
  })

  context('Test election system functionality', () => {

    it('initializes new election', async () => {
      const blockNumber = await web3.eth.getBlockNumber()
      let tx = await electionSystem.initializeElection(blockNumber, blockNumber + 100, blockNumber + 120, 'eth denver hackers voting', coloradoCoin.address, { from: accounts[0] });

      const result = tx.logs[1].args

      electionId = result.electionId
    })

    it('sends a vote', async () => {
      const tx = await electionSystem.sendVote(toHex(electionId), true, { from: accounts[1] });

      const result = tx.logs[0].args
      assert.equal(result.voteId.toString(), electionId.toString())
      assert.equal(result.voter, accounts[1].toLowerCase())
      assert.equal(result.stake.toNumber(), 10000)

    })

    it('sends another vote', async () => {

      let tx = await electionSystem.sendVote(toHex(electionId), false, { from: accounts[2] })

      const result = tx.logs[0].args
      assert.equal(result.voteId.toString(), electionId.toString())
      assert.equal(result.voter, accounts[2].toLowerCase())
      assert.equal(result.stake.toNumber(), 20000)

    })

    it('should try to cheat during grace period', async () => {
      await mineBlocks(100)//Skip past end of voting period

      //Try to vote after voting period
      try {
        await electionSystem.sendVote(toHex(electionId), true, { from: accounts[4] })
      } catch (e) {
        assert.equal(e.message, "VM Exception while processing transaction: revert")
      }

      //Try to add more weight to vote during grace period
      await coloradoCoin.transfer(accounts[1], 10000, { from: accounts[0] })

      await electionSystem.changeBalance(toHex(electionId), accounts[1], { from: accounts[3] })
    })

    it('get final election results', async () => {

      await mineBlocks(20)

      const electionResults = await electionSystem.getElectionResults(toHex(electionId))
      assert.equal(electionResults[0].toNumber(), 10000)
      assert.equal(electionResults[1].toNumber(), 20000)
    })
  })
})