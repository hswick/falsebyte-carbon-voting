const program = require('commander')

const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"))

const ElectionSystem = artifacts.require('ElectionSystem')
const ColoradoCoin = artifacts.require('ColoradoCoin')

let electionSystem = ElectionSystem.at(ElectionSystem.address)
let coloradoCoin = ColoradoCoin.at(ColoradoCoin.address)

const mineBlocks = require('./test/helpers/mineBlocks')(web3)

const main = async () => {
  const accounts = await web3.eth.getAccounts()

  program
  .version('0.0.1')
  .description("CLI for FalseByte Carbon Voting")

  program
    .command('foo')
    .description('Testing out commander')
    .action(async function() {
      console.log('foobar')
    })
  
  program
    .command('election [description] [numBlocks]')
    .description('Testing out commander')
    .action(async function (description, numBlocks) {
      console.log(description + " vote for " + numBlocks)
      const blockNumber = await web3.eth.getBlockNumber()
      tx = await electionSystem.initializeElection(blockNumber, blockNumber+parseInt(numBlocks), blockNumber+parseInt(numBlocks)+10, description, coloradoCoin.address, {from: accounts[0]})
      console.log("Election ID: " + tx.logs[1].args.electionId.toString(16))
    })

  program
    .command('transfer [accountNumber] [value]')
    .description('Transfer funds to [accountNumber]')
    .action(async function(accountNumber, value) {
      const account = accounts[accountNumber]
      console.log("Transferring " + value + " tokens to " + account.toLowerCase())
      await coloradoCoin.transfer(account, value, {from: accounts[0]})
    })

  program
  .command('balance [accountNumber')
  .description('Get balance of account')
  .action(async function(accountNumber) {
    const balance = await coloradoCoin.balanceOf.call(accounts[accountNumber])
    console.log("Balance is: " + balance)
  })

  program
    .command('vote [electionID] [voteBool] [accountNumber]')
    .description('Send vote to election')
    .action(async function (electionID, voteBool, accountNumber) {
      const account = accounts[accountNumber]
      await electionSystem.sendVote(web3.utils.toBN(electionID).toString(), voteBool, {from: account})
      console.log("Sent vote " + voteBool + " from " + account)
    })

  program
    .command('skip [numBlocks]')
    .description('skip number of blocks')
    .action(async function(numBlocks) {
      console.log('Skipping past ' + numBlocks + " blocks")
      await mineBlocks(numBlocks)
      console.log('Current block number is: ' + await web3.eth.getBlockNumber())
    })

  program
    .command('results [electionID]')
    .description('get final results of the election')
    .action(async function(electionID) {
      const results = await electionSystem.getElectionResults.call(web3.utils.toBN(electionID).toString())
      console.log("Final yes vote total: " + results[0].toNumber() + " Final no vote total: " + results[1].toNumber())
    })
  
  program.parse(['/usr/local/bin/node', 'cli.js'].concat(process.argv.slice(4)))
}

module.exports = async (cb) => {
  main()
  cb()
}