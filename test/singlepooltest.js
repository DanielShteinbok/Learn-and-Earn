const Course = artifacts.require("Course");
const Token = artifacts.require("TestCoin");
const fs = require("fs");

contract("SinglePool", function(accounts) {
	it("Should get currentPool, pay 3 Token to it, add two completers, and then call the Course's payout", async function (){
		const token = await Token.deployed();
		const course = await Course.deployed();
		const addr = await course.getCurrentPool();
		const pool = new web3.eth.Contract(JSON.parse(fs.readFileSync("../build/contracts/SinglePool.json")).abi, addr);
		console.log(await pool.options.address);
		pool.methods.admin().call().then(console.log);
//		console.log("SinglePool admin address: " + await pool.getAdmin() + '\n');
		console.log("accounts[0]: " + accounts[0] + '\n');
		const maturityBlock = await course.getMaturity();
		token.transfer(addr, 3, {from: accounts[0]});

		pool.methods.addCompleter(accounts[0]).send({from: accounts[0]});
		pool.methods.addCompleter(accounts[1]).send({from: accounts[0]});
		console.log("\ngetMaturity: " + await course.getMaturity());
		console.log("\npoolMaturity: " + await course.poolMaturity());
		console.log("\nstart of current pool: " + (await course.getMaturity() - await course.poolMaturity())); 
		token.getPastEvents("Transfer", {
			filter: {from: accounts[0], to: addr}, 
			fromBlock: (await course.getMaturity() - await course.poolMaturity()), 
			toBlock: "latest"
			}, 
			function (error, events) {
				console.log("events: " + events);
				for (eventItem in events) {
					console.log("event value: " + eventItem.returnValues.value + '\n');
					//assert(eventItem.returnValues.value >= await course.buyInPrice(), "The cheapskate payed less than he ought to!");
					console.log(eventItem);
				}
			}
			
		);
		assert.equal(await token.balanceOf(addr), 3, "Pool is missing money!");
	//	console.log(await token.balanceOf(addr));
		web3.eth.subscribe("newBlockHeaders").on("data", async function(blockHeader) {
			console.log("block number is: " + blockHeader.number);
			if (blockHeader.number >= maturityBlock) {
				console.log("block number is: " + blockHeader.number);
				
				try {
					await course.payOut();
					console.log("payout succeeded--that is probably good\n");
					console.log("balance of accounts[0]: " + token.balanceOf(accounts[0]) + '\n');
					console.log("balance of accounts[1]: " + token.balanceOf(accounts[1]) + '\n');
				}
				catch (e) {
					console.log("payout failed--and that is probably bad");
				}
				const courseMaturity = await course.getMaturity();
				console.log(courseMaturity);
				assert(addr != await course.getCurrentPool(), "Pool has not changed, so payout has not succeeded");
				assert(courseMaturity > await maturityBlock, "block at which pool matures probably hasn't changed");
			}
		});
		assert( await token.getPastEvents("Transfer", {
			filter: {from: accounts[3], to: addr}, 
			fromBlock: await course.getMaturity() - await course.poolMaturity(), 
			toBlock: "latest"
			}), "Cannot get transaction event");	
		console.log("I actually got here!");	
	});
});
