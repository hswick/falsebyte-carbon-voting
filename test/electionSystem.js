const ElectionSystem = artifacts.require('./ElectionSystem.sol')
const ColoradoCoin = artifacts.require('./ColoradoCoin.sol')
const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"))

describe('ElectionSystem', function () {
  let electionSystem

  before(async () => {
    electionSystem = await ElectionSystem.new()
    coloradoCoin = await ColoradoCoin.new()
  })

  context('Test election system functionality', () => {

    it('initializes new election', async () => {
      const blockNumber = await web3.eth.getBlockNumber()
      electionSystem.initializeElection(blockNumber, blockNumber+100, blockNumber+120, 'eth denver hackers voting', coloradoCoin.address);
    })
  })
})