const Course = artifacts.require("Course");

contract('Course', function(accounts) {
	it("Should get currentPool, a non-zero address", async function (){
		const course = await Course.deployed();
		const addr = await course.getCurrentPool();
		assert(addr != '0x0000000000000000000000000000000000000000', "address returned is zero");
		console.log("current address is " + addr + '\n');
		return addr;
	});
	/* it("Should get list of all pool addresses", async function() {
		const course = await Course.deployed();
		const addrList = await course.getAllPools();
		console.log("all pools are: ", addrList);
		return addrList;
	}); */
	it("Should get each pool address by iterating through each index of allPools", async function(){
		const course = await Course.deployed();
		var poolArray = [];
		var index = 0;
		var numberPools = await course.poolMaturity();
		numberPools /= await course.buyInTime();
		numberPools = Math.floor(numberPools);
		++numberPools;
		console.log("number of pools should be: " + numberPools);
		while (await course.allPools(index) != '0x0000000000000000000000000000000000000000') {
			console.log("The next pool is: " + await course.allPools(index) + '\n');
			poolArray.push(await course.allPools(index));
			++index;
		}
		console.log("allPools is: " + poolArray + '\n');
		assert(poolArray.length == numberPools, "number of pools is not what it should be");
		return poolArray;
	});
	it("Should not allow one to call payOut() until time is up", async function(){
		const course = await Course.deployed();
		const addr = await course.getCurrentPool();
		const courseMaturity = await course.getMaturity();
		try {
			await course.payOut();
			console.log("payout succeeded--that is probably bad");
		}
		catch (e) {
			console.log("payout failed--and that is probably good");
		}
		console.log(courseMaturity);
		assert.equal(addr, await course.getCurrentPool(), "Pool has changed, so payout succeeded");
		console.log("Current block: " + (await web3.eth.getBlock("latest")).number + '\n');
		console.log("Start time: " + await course.startTime() + '\n');
		console.log("Maturity time: " + await course.poolMaturity() + '\n');
		console.log("Pool maturity at: " + await course.getMaturity() + '\n');
		assert(courseMaturity > (await web3.eth.getBlock("latest")).number, "Too late; course has matured before payout was called");
	});
	it("Should call payout when time has passed", async function() {
		const course = await Course.deployed();
		const maturityBlock = await course.getMaturity();
		const addr = await course.getCurrentPool();
		console.log("pool maturity at block: " + maturityBlock);
		web3.eth.subscribe("newBlockHeaders").on("data", async function(blockHeader) {
			if (blockHeader.number >= maturityBlock) {
				console.log("block number is: " + blockHeader.number);
				
				try {
					await course.payOut();
					console.log("payout succeeded--that is probably good");
				}
				catch (e) {
					console.log("payout failed--and that is probably bad");
				}
				const courseMaturity = await course.getMaturity();
				console.log(courseMaturity);
				assert(addr != await course.getCurrentPool(), "Pool has not changed, so payout has not succeeded");
				assert(courseMaturity > maturityBlock, "block at which pool matures probably hasn't changed");
			}
		});
	});
});
		
