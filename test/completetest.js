const Course = artifacts.require("Course");
const fs = require("fs");

const token = new web3.eth.Contract(JSON.parse(fs.readFileSync("./build/contracts/IERC20.json")).abi, "0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108");
const link = new web3.eth.Contract(JSON.parse(fs.readFileSync("./build/contracts/IERC20.json")).abi, "0x20fE562d797A42Dcb3399062AE9546cd06f63280");

contract("Course initialization and state", function(accounts) {
	console.log(accounts);
	it("should initialize", async function (){
		const course = await Course.deployed();
		link.methods.transfer(course.address, "4000000000000000000").send({from: accounts[0]});
		//assert(link.methods.balanceOf(course.address).call() == 4, "course doesn't have 4 link tokens");
		course.initialize({from: accounts[0]})
		.then(async function() {
			// ensure that truffle has 2 link tokens
			assert(link.methods.balanceOf(course.address).call() == 2, "course doesn't have 2 link tokens");
			// print out the buyInStartTime
			console.log("buy-in start time: ");
			console.log(await course.buyInStartTime());
			console.log("\ncurrent pool: ");
			console.log(await course.getCurrentPool());
			assert(course.getCurrentPool() == course.getPoolByIndex(0), "current pool is not zeroth pool");
			const currentPool = new web3.eth.Contract(JSON.parse(fs.readFileSync("./build/contracts/SinglePool.json")).abi, course.getCurrentPool());
			console.log(currentPool.options.address);
//			token.methods.transfer(currentPool.options.address, 3).send({from: accounts[0]})
//			.then(assert(token.methods.balanceOf(currentPool.options.address) == 3, "funds not sent over to pool"));
			currentPool.methods.addCompleter(accounts[0]).send({from: accounts[0]});
			currentPool.methods.addCompleter(accounts[1]).send({from: accounts[0]});
		});
	});
/*	
	it("should add a completer to current pool", async function() {
		const currentPool = new web3.eth.Contract(JSON.parse(fs.readFileSync("./build/contracts/SinglePool.json")).abi, await (await Course.deployed()).getCurrentPool());
		console.log(currentPool.options.address);
		token.methods.transfer(currentPool.options.address, 3).send({from: accounts[0]})
		.then(assert(token.methods.balanceOf(currentPool.options.address) == 3, "funds not sent over to pool"));
		currentPool.methods.addCompleter(accounts[0]).send({from: accounts[0]});
		currentPool.methods.addCompleter(accounts[1]).send({from: accounts[0]});
	}); */
});
		
		
