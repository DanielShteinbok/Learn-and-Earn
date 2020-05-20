pragma solidity >=0.4.21 < 0.7.0;

import "./SinglePool.sol";
// import ChainlinkClient.sol
import "../../chainlink/evm-contracts/src/v0.6/ChainlinkClient.sol";

// from aave:
// import LendingPoolAddressesProvider
// import ../../aave-protocol/contracts/lendingpool/LendingPoolAddressesProvider
// import LendingPool

contract Course is ChainlinkClient {
	//configuration stuff
	uint public buyInTime;
	uint public poolMaturity;
	uint public buyInPrice;
	address public admin;
	address public tokenAddress;

	//chainlink stuff
	address public chainlinkOracle;
	bytes32 public chainlinkJobId;
	uint public chainlinkPayment = 1 * LINK;

	//aave stuff
	address public aaveProviderAddress;
	address public aTokenAddr;

	// true state variables
	//uint public startTime;
	uint public maturityCycleStart;
	uint public buyInStartTime;
	// the number of SinglePool s in allPools is known at construction time to be:
	// uint(poolMaturity/buyInTime) + 1
	mapping (uint8 => SinglePool) private allPools;

	//nextToMature stores the index of the next SinglePool to mature
	uint8 public nextToMature; 
	uint8 public currentBuyInPool;
	modifier adminOnly {
		require (msg.sender == admin);
		_;
	}


	// TODO: modifier timeIsRight;
	// see below.
	modifier poolIsMature {
		require(now >= maturityCycleStart + poolMaturity + (uint(poolMaturity/buyInTime)+1-nextToMature)*buyInTime);
		_;
	}

	modifier buyInOver {
		require(now >= buyInStartTime + buyInTime*currentBuyInPool); 
		_;
	}


	constructor(uint _buyInTime, uint _poolMaturity, uint _buyInPrice, 
address _tokenAddress, address _oracle, bytes32 _jobId, address _aaveToken, address _aaveProvider, address _linkAddr) public {
		buyInTime = _buyInTime;
		poolMaturity = _poolMaturity;
		buyInPrice = _buyInPrice;
		tokenAddress = _tokenAddress;
		admin = msg.sender;
		// startTime = block.number;
		maturityCycleStart = now;
		buyInStartTime = now;
		aTokenAddr = _aaveToken;
		aaveProviderAddress = _aaveProvider;
		for (uint8 i=0; i < uint(poolMaturity/buyInTime) + 1; ++i) {
			allPools[i] = new SinglePool(admin);
		}
		chainlinkOracle = _oracle;
		chainlinkJobId = _jobId;
		if (_linkAddr == address(0)) {
			setPublicChainlinkToken();
		} else {
			setChainlinkToken(_linkAddr);
		}
		Chainlink.Request memory investReq = buildChainlinkRequest(chainlinkJobId, address(this), this.invest.selector);
		investReq.addUint("until", buyInStartTime + buyInTime);
		sendChainlinkRequestTo(chainlinkOracle, investReq, chainlinkPayment);

		Chainlink.Request memory payoutReq = buildChainlinkRequest(chainlinkJobId, address(this), this.payOut.selector);
		payoutReq.addUint("until", buyInStartTime + currentBuyInPool * buyInTime + poolMaturity);
		sendChainlinkRequestTo(chainlinkOracle, payoutReq, chainlinkPayment);
	}

	function invest() public buyInOver {
		allPools[currentBuyInPool].invest(tokenAddress, aaveProviderAddress);
		currentBuyInPool = uint8((currentBuyInPool + 1) % uint(poolMaturity/buyInTime + 1));
		if (currentBuyInPool == 0)
			buyInStartTime += (uint(poolMaturity/buyInTime) + 1) * buyInTime;
		Chainlink.Request memory investReq = buildChainlinkRequest(chainlinkJobId, address(this), this.invest.selector);
		investReq.addUint("until", buyInStartTime + (currentBuyInPool + 1) * buyInTime);
		sendChainlinkRequestTo(chainlinkOracle, investReq, chainlinkPayment);
		Chainlink.Request memory payoutReq = buildChainlinkRequest(chainlinkJobId, address(this), this.payOut.selector);
		payoutReq.addUint("until", buyInStartTime + currentBuyInPool * buyInTime + poolMaturity);
		sendChainlinkRequestTo(chainlinkOracle, payoutReq, chainlinkPayment);
	}

	function payOut() public poolIsMature {
		allPools[nextToMature].reset(tokenAddress, aTokenAddr);
		nextToMature = uint8((nextToMature + 1) % uint(poolMaturity/buyInTime + 1));
		if (nextToMature == 0)
			maturityCycleStart += (uint(poolMaturity/buyInTime) + 1) * buyInTime;
	}

	function getCurrentPool() public view returns (address) {
		return address(allPools[ currentBuyInPool ]);
	}

	/*function getAllPools() public view returns (address[] memory) {
		address[] memory poolAddresses;
		for (uint8 i = 0; i < uint8(poolMaturity/buyInTime) + 1; ++i) {
			poolAddresses[i] = address(allPools[i]);
		}	
		return poolAddresses;
	}*/

	function getMaturity() public view returns (uint) {
		// fix: change (uint(poolMaturity/buyInTime)+1-nextToMature) to: nextToMature
		return maturityCycleStart + poolMaturity + nextToMature*buyInTime;
	}

	function getPoolByIndex(uint8 poolIndex) public view returns (address) {
		return address(allPools[poolIndex]);
	}
}
