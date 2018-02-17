var Migrations = artifacts.require("./Migrations.sol");
let ElectionSystem = artifacts.require('ElectionSystem')
let ColoradoCoin = artifacts.require('ColoradoCoin')

const fs = require('fs')

module.exports = async function(deployer) {
  await deployer.deploy(Migrations);
  await deployer.deploy(ElectionSystem)
  await deployer.deploy(ColoradoCoin)

  fs.writeFile('./config.json', JSON.stringify({
    'electionSystemAddress': ElectionSystem.address,
    'coloradoCoinAddress': ColoradoCoin.address
  }), (err) => { if(err) console.error(err)})
};