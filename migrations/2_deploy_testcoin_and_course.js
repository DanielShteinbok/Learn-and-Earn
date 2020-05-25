const TestCoin = artifacts.require("TestCoin");
const Course = artifacts.require("Course");

module.exports = function(deployer) {
	// assuming deployment to Ropsten
	//const buyInTime = 1209600; // 2 weeks in seconds
	//const poolMaturity = 3024000; // 5 weeks in seconds
	const buyInTime = 120; // two minutes in seconds
	const poolMaturity = 300; // five minutes in seconds
	const buyInPrice = 2; // buy-in price in lowest denominations of Bokky tokens, see below
	const daiContract = "0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108"; // mock DAI contract on Ropsten
	const oracle = "0xc99B3D447826532722E41bc36e644ba3479E4365"; // alarm clock chainlink address on Ropsten, see README
	const jobId = "0x2ebb1c1a4b1e4229adac24ee0b5f784f00000000000000000000000000000000"; // chainlink alarm clock job ID, padded to 32 bytes. See README.
	const aaveToken = "0xcB1Fe6F440c49E9290c3eb7f158534c2dC374201"; // aDAI contract on Ropsten
	const aaveProvider = "0x1c8756FD2B28e9426CDBDcC7E3c4d64fa9A54728"; // aave LendingPoolAddressesProvider contract on Ropsten
	const linkAddr = "0x20fE562d797A42Dcb3399062AE9546cd06f63280"; // chainlink LINK contract address on Ropsten
	deployer.deploy(Course, buyInTime, poolMaturity, buyInPrice, daiContract, oracle, jobId, aaveToken, aaveProvider, linkAddr);
};
