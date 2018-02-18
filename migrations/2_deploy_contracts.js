let ElectionSystem = artifacts.require('ElectionSystem')
let CommitElectionSystem = artifacts.require('CommitElectionSystem')
let ColoradoCoin = artifacts.require('ColoradoCoin')

const fs = require('fs')

module.exports = async function(deployer) {

  deployer.deploy(CommitElectionSystem)
  deployer.deploy(ElectionSystem)
  deployer.deploy(ColoradoCoin)

  await new Promise((resolve, reject) => {
    setTimeout(() => { resolve()}, 4000)
  })

  fs.writeFile('./config.json', JSON.stringify({
    'electionSystemAddress': ElectionSystem.address,
    'commitElectionSystemAddress': CommitElectionSystem.address,
    'coloradoCoinAddress': ColoradoCoin.address
  }), (err) => { if(err) console.error(err)})
};

