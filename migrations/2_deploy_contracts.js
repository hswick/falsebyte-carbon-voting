const ElectionSystem = artifacts.require('ElectionSystem')
const ColoradoCoin = artifacts.require('ColoradoCoin')

module.exports = async (deployer, network) => {
  await deployer.deploy(ElectionSystem)
  await deployer.deploy(ColoradoCoin)

  console.log(`
  ELECTION_SYSTEM_ADDRESS=${ElectionSystem.address}
  COLORADO_COIN_ADDRESS=${ColoradoCoin.address}
  `)
}