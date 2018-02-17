const ElectionSystem = artifacts.require('ElectionSystem')

module.exports = async (deployer, network) => {
  await deployer.deploy(ElectionSystem)

  console.log(`ELECTION_SYSTEM_ADDRESS=${ElectionSystem.address}`)
}