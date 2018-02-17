
var fs = require("fs")
var Web3 = require('web3')
var web3 = new Web3()

var dir = "../build/"
var host = "localhost"

// var code = "0x" + fs.readFileSync(dir + "Coindrop.bin")
var config = JSON.parse(fs.readFileSync(dir + "ElectionSystem.abi"))

// args: address that has changed
web3.setProvider(new web3.providers.WebsocketProvider('ws://' + host + ':8546'))

var vote = new web3.eth.Contract(config.abi, config.address)

async function update(voteid, address) {
    console.log("updating at vote", voteid, "voter", address)
    var accts = await web3.eth.getAccounts()
    var send_opt = {gas:4700000, from:accts[0]}
    vote.methods.changeBalance(voteid, address).send(send_opt)
}

update(process.argv[2], process.argv[3])

