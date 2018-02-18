module.exports = () => {
  return (config) => {
    let voters = {}
    let castVoteEvent, transferEvent

    return [
      new Promise(async (resolve, reject) => {
        castVoteEvent = config.electionSystem.CastVote({electionId: config.electionId})
        castVoteEvent.watch(async (err, result) => {
          if(result) {
            const stake = result.args.stake.toNumber()
            voters[result.args.voter] = stake
            console.log("Vote sent from: " + result.args.voter + " for " + stake + " tokens")
          }
        })
  
        transferEvent = config.erc20.Transfer()
        transferEvent.watch(async (err, result) => {
          if(result) {
            const from = result.args._from;
            const to = result.args._to;

            console.log('Transfer sent from ' + from + ' to ' + to)
  
            if(from in voters) {
              await config.electionSystem.changeBalance(config.electionId, from, {from: config.monitoringAccount})
            }
  
            if(to in voters) {
              await config.electionSystem.changeBalance(config.electionId, to, {from: config.monitoringAccount})
            }
          }
        })
      }),
      () => {
        castVoteEvent.stopWatching()
        transferEvent.stopWatching()
      }
    ]
  }
}