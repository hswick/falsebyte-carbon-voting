const ElectionSystem = artifacts.require('./ElectionSystem.sol')
const ColoradoCoin = artifacts.require('./ColoradoCoin.sol')
const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"))
const mineBlocks = require('./helpers/mineBlocks')(web3)


const DAOFactory = artifacts.require('@aragon/os/contracts/factory/DAOFactory.sol');
const EVMScriptRegistryFactory = artifacts.require('@aragon/os/contracts/factory/EVMScriptRegistryFactory.sol')
const ACL = artifacts.require('@aragon/os/contracts/acl/ACL.sol')
const Kernel = artifacts.require('@aragon/os/contracts/kernel/Kernel.sol')
const ANY_ADDR = '0xffffffffffffffffffffffffffffffffffffffff'

function toHex(x) {
    var str = x.toString(16)
    while (str.length < 64) str = "0"+str
    return "0x"+str
}

describe('ElectionSystem', async function () {
  this.timeout(120000)
  
  let electionSystem, accounts, electionId

  let daoFact, kernal, acl, app, token, executionTarget = {}

  const votingTime = 1000;

  before(async () => {
    const regFact = await EVMScriptRegistryFactory.new();
    kernel = await Kernel.new();
    acl = await ACL.new();
    daoFact = await DAOFactory.new(kernel.address, acl.address, regFact.address);
    coloradoCoin = await ColoradoCoin.at(ColoradoCoin.address)

    accounts = await web3.eth.getAccounts()

    //send colorado coins to accounts
    await coloradoCoin.transfer(accounts[1], 10000, { from: accounts[0] })
    await coloradoCoin.transfer(accounts[2], 20000, { from: accounts[0] })

    const r = await daoFact.newDAO(accounts[0])
    const dao = Kernel.at(r.logs.filter(l => l.event == 'DeployDAO')[0].args.dao)
    acl = ACL.at(await dao.acl())
    
    const receipt = await dao.newAppInstance('0x1234', (await ElectionSystem.new()).address, { from: accounts[0] })
   
    electionSystem = ElectionSystem.at(receipt.logs.filter(l => l.event == 'NewAppProxy')[0].args.proxy)
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

      let tx = await electionSystem.sendVote(toHex(electionId), false, { from: accounts[2] });

      const result = tx.logs[0].args
      assert.equal(result.voteId.toString(), electionId.toString())
      assert.equal(result.voter, accounts[2].toLowerCase())
      assert.equal(result.stake.toNumber(), 20000)

    })

    it('change voter balance', async () => {
      const tx = await coloradoCoin.transfer(accounts[1], 10000, { from: accounts[0] })

      const result = tx.logs[0].args

      await electionSystem.changeBalance(toHex(electionId), result._to, { from: accounts[3] })
    })

    it('change voter balance again', async () => {
      const tx = await coloradoCoin.transfer(accounts[0], 10000, { from: accounts[1] })

      const result = tx.logs[0].args

      // var str = electionSystem.contract.changeBalance.getData(electionId, result._from, {from: accounts[3]})
      // console.log(str)
      await electionSystem.changeBalance(toHex(electionId), result._from, { from: accounts[3] })
    })

    it('get final election results', async () => {

      await mineBlocks(120)

      const electionResults = await electionSystem.getElectionResults(toHex(electionId))
      assert.equal(electionResults[0].toNumber(), 10000)
      assert.equal(electionResults[1].toNumber(), 20000)
    })
  })
})