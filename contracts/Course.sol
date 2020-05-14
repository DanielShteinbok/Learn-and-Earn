pragma solidity >=0.4.21 < 0.7.0;

import "./SinglePool.sol";

contract Course {
	uint public startTime;
	uint public buyInTime;
	uint public poolMaturity;
	uint public buyInPrice;
	address public admin;
	address public tokenAddress;

	// the number of SinglePool s in allPools is known at construction time to be:
	// uint(poolMaturity/buyInTime) + 1
	mapping (uint8 => SinglePool) public allPools;

	//nextToMature stores the index of the next SinglePool to mature
	uint8 nextToMature; 

	modifier adminOnly {
		require (msg.sender == admin);
		_;
	}
	// TODO: modifier timeIsRight;
	// see below.
	modifier poolIsMature {
		require(block.number >= startTime + poolMaturity + (uint(poolMaturity/buyInTime)+1-nextToMature)*buyInTime);
		_;
	}

	constructor(uint _buyInTime, uint _poolMaturity, uint _buyInPrice, address _tokenAddress) public {
		buyInTime = _buyInTime;
		poolMaturity = _poolMaturity;
		buyInPrice = _buyInPrice;
		tokenAddress = _tokenAddress;
		admin = msg.sender;
		startTime = block.number;
		for (uint8 i=0; i < uint(poolMaturity/buyInTime) + 1; ++i) {
			allPools[i] = new SinglePool(admin);
		}
	}

	function payOut() public poolIsMature {
		allPools[nextToMature].reset(tokenAddress);
		nextToMature = uint8((nextToMature + 1) % uint(poolMaturity/buyInTime + 1));
		if (nextToMature == 0)
			startTime += (uint(poolMaturity/buyInTime) + 1) * buyInTime;
	}

	function getCurrentPool() public view returns (address) {
		return address(allPools[ uint8((block.number - startTime)/buyInTime) ]);
	}

	/*function getAllPools() public view returns (address[] memory) {
		address[] memory poolAddresses;
		for (uint8 i = 0; i < uint8(poolMaturity/buyInTime) + 1; ++i) {
			poolAddresses[i] = address(allPools[i]);
		}	
		return poolAddresses;
	}*/

	function getMaturity() public view returns (uint) {
		return startTime + poolMaturity + (uint(poolMaturity/buyInTime)+1-nextToMature)*buyInTime;
	}
}
