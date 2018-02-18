module.exports = () => {
  return async (config) => {
    let voters = {}

    return new Promise(async (resolve, reject) => {
      let castVoteEvent = config.electionSystem.CastVote({electionId: config.electionId})
      castVoteEvent.watch(async (err, result) => {
        if(result) {
          voters[result.args.voter] = result.args.stake.toNumber()
        }
      })

      let transferEvent = config.erc20.Transfer()
      transferEvent.watch(async (err, result) => {
        if(result) {
          const from = result.args._from;
          const to = result.args._to;

          if(from in voters) {
            await config.electionSystem.changeBalance(config.electionId, from, {from: config.monitoringAccount})
          }

          if(to in voters) {
            await config.electionSystem.changeBalance(config.electionId, to, {from: config.monitoringAccount})
          }
        }
      })

      await new Promise((resolve, reject) => {
        setTimeout(() => {resolve()}, 10000)
      })

      castVoteEvent.stopWatching()
      transferEvent.stopWatching()
      //config.erc20.Transfer()
    })
  }
}