const TestCoin = artifacts.require("TestCoin");
const Course = artifacts.require("Course");

module.exports = function(deployer) {
	deployer.deploy(TestCoin).then(function() {
		return deployer.deploy(Course, 10, 15, 2, TestCoin.address, TestCoin.address, "0x0000000000000000000000000000000000000000000000000000000000000000", TestCoin.address, TestCoin.address, TestCoin.address)
	});
};
