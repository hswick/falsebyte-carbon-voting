const ElectionSystem = artifacts.require('./CommitElectionSystem.sol')
const ColoradoCoin = artifacts.require('./ColoradoCoin.sol')
const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"))
const mineBlocks = require('./helpers/mineBlocks')(web3)

function toHex(x) {
    var str = x.toString(16)
    while (str.length < 64) str = "0"+str
    return "0x"+str
}

describe('CommitElectionSystem', async function () {
  this.timeout(120000)

  let electionSystem, accounts, electionId, secret, true_byte, secret2

  before(async () => {

    electionSystem = await ElectionSystem.at(ElectionSystem.address)
    coloradoCoin = await ColoradoCoin.at(ColoradoCoin.address)

    accounts = await web3.eth.getAccounts()
    secret = Buffer.from("0102030405060708091011121314151617181920212223242526272829303132", "hex")
    secret2 = Buffer.from("010102030405060708091011121314151617181920212223242526272829303132", "hex")
    true_byte = Buffer.from("01", "hex")

    //send colorado coins to accounts
    await coloradoCoin.transfer(accounts[1], 10000, {from: accounts[0]})
    await coloradoCoin.transfer(accounts[2], 20000, {from: accounts[0]})
    
  })

  context('Test election system functionality', () => {

    it('initializes new election', async () => {
      const blockNumber = await web3.eth.getBlockNumber()
      let tx = await electionSystem.initializeElection(blockNumber, blockNumber+100, blockNumber+120, blockNumber+170, 'eth denver hackers voting', coloradoCoin.address, {from: accounts[0]});

      const result = tx.logs[1].args

      electionId = result.electionId
    })

    it('sends a vote', async () => {
        var hashed = web3.utils.sha3(secret2)
      const tx = await electionSystem.sendVote(toHex(electionId), hashed, {from: accounts[1]});
      const res = await electionSystem.checkVote.call(true, secret.toString(), {from: accounts[1]});
    })

    it('reveal vote', async () => {
      await mineBlocks(120)

      const tx = await electionSystem.revealVote(toHex(electionId), true, secret.toString(), {from: accounts[1]})
      const result = tx.logs[0].args
      assert.equal(result.voteId.toString(), electionId.toString())
      assert.equal(result.voter, accounts[1].toLowerCase())
      assert.equal(result.stake.toNumber(), 10000)

    })

    it('get final election results', async () => {

      await mineBlocks(100)

      const electionResults = await electionSystem.getElectionResults(toHex(electionId))
      assert.equal(electionResults[0].toNumber(), 10000)
      // assert.equal(electionResults[1].toNumber(), 20000)
    })
  })
})