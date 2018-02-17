
var fs = require("fs")
var Web3 = require('web3')
var web3 = new Web3()

var dir = "../build/contracts/"
var host = "localhost"

var config = JSON.parse(fs.readFileSync(dir + "ElectionSystem.json"))

web3.setProvider(new web3.providers.HttpProvider('http://' + host + ':8545'))

function findAddress(blah) {
    for (i in blah) {
        if (blah[i].address) return blah[i].address
    }
}

var vote = new web3.eth.Contract(config.abi, findAddress(config.networks))

async function update(voteid, address) {
    console.log("updating at vote", voteid, "voter", address)
    var accts = await web3.eth.getAccounts()
    var send_opt = {gas:4700000, from:accts[0]}
    vote.methods.changeBalance(voteid, web3.utils.toChecksumAddress(address)).send(send_opt)
}

// args: vote id, address that has changed
update(process.argv[2], process.argv[3])

