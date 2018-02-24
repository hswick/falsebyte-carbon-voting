const ElectionSystem = artifacts.require('./ElectionSystem.sol')
const ColoradoCoin = artifacts.require('./ColoradoCoin.sol')
const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"))
const mineBlocks = require('./helpers/mineBlocks')(web3)
const toHex = require('./helpers/toHex')
const monitoringAgent = require('../agent')()

describe('MonitoringAgent', async function () {
  this.timeout(120000)

  let electionSystem, accounts, electionId, stopper

  before(async () => {

    electionSystem = await ElectionSystem.at(ElectionSystem.address)
    coloradoCoin = await ColoradoCoin.at(ColoradoCoin.address)

    accounts = await web3.eth.getAccounts()

    //send colorado coins to accounts
    await coloradoCoin.transfer(accounts[1], 10000, {from: accounts[0]})
    await coloradoCoin.transfer(accounts[2], 20000, {from: accounts[0]})
  })

  context('Test election system functionality with monitor', () => {

    it('initializes new election', async () => {
      const blockNumber = await web3.eth.getBlockNumber()
      let tx = await electionSystem.initializeElection(blockNumber, blockNumber+100, blockNumber+120, 'eth denver hackers voting', coloradoCoin.address, {from: accounts[0]});

      const result = tx.logs[1].args
      console.log(result.electionId.toString(16), result.electionId.toString(16).length, toHex(result.electionId))
      
      electionId = result.electionId

      let [monitorPromise, _stopper] = monitoringAgent({
        electionSystem: electionSystem, 
        erc20: coloradoCoin, 
        electionId: electionId,
        monitoringAccount: accounts[0]
      })

      stopper = _stopper
    })

    it('sends a vote', async () => {
      const tx = await electionSystem.sendVote(toHex(electionId), true, {from: accounts[1]});

      const result = tx.logs[0].args
      assert.equal(result.voteId.toString(), electionId.toString())
      assert.equal(result.voter, accounts[1].toLowerCase())

    })

    it('sends another vote', async () => {

      let tx = await electionSystem.sendVote(toHex(electionId), false, {from: accounts[2]});

      const result = tx.logs[0].args
      assert.equal(result.voteId.toString(), electionId.toString())
      assert.equal(result.voter, accounts[2].toLowerCase())

    })

    it('change voter balance', async () => {
      const tx = await coloradoCoin.transfer(accounts[1], 10000, {from: accounts[0]})
    })

    it('change voter balance again', async () => {
      const tx = await coloradoCoin.transfer(accounts[0], 10000, {from: accounts[1]})
    })

    it('get final election results', async () => {

      await new Promise((resolve, reject) => {
        setTimeout(() => { resolve()}, 3000)
      })

      await mineBlocks(120)

      const electionResults = await electionSystem.getElectionResults(toHex(electionId))
      assert.equal(electionResults[0].toNumber(), 10000)
      assert.equal(electionResults[1].toNumber(), 20000)
    })

    it('stops monitoring agent', () => {
      stopper()
    })
  })
})