const HDWalletProvider = require("@truffle/hdwallet-provider");
var fs = require("fs");
// I am reading a file containing my mnemonic here, so as not to expose my mnemonic to my fellow Githubbers.
// feel free to: either create your own ../mnemonic-compromised with your own mnemonic, or:
// remove the whole file-reading bit and straight up stick a string here (note that you may also remove line 2 in that case)
// or change "../mnemonic-compromised" to the name of another file that has your mnemonic in it
// or do whatever you like. It's your Happy Meal!
let mnemonic = fs.readFileSync("../mnemonic-compromised", {encoding:'utf8', flag:'r'}).trim();
console.log(mnemonic);
console.log("something's up");
module.exports = {
	compilers: {
		solc: {
			version: "0.6.7"
		}
	},
	networks: {
		ropsten: {
			provider: function() {
				return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/v3/90db0ed21539409a97bea118f37c781e")
			},
			network_id: 3
		}
	}
};
