const defaultConfig = {
  // eslint-disable-next-line camelcase
  network_id: '*',
  gas: 5000000,
  gasPrice: 4000000000, // gwei
}

module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      ...defaultConfig,
    }
  }
}