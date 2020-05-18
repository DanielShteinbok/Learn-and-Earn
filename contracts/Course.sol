pragma solidity >=0.4.21 < 0.7.0;

import "./SinglePool.sol";
// import ChainlinkClient.sol
import "../../chainlink/evm-contracts/src/v0.6/ChainlinkClient.sol";

contract Course is ChainlinkClient {
	uint public startTime;
	uint public buyInTime;
	uint public poolMaturity;
	uint public buyInPrice;
	address public admin;
	address public tokenAddress;
	address public chainlinkOracle;

	bytes32 public chainlinkJobId;
	uint public chainlinkPayment = 1 * LINK;

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
		require(now >= startTime + poolMaturity + (uint(poolMaturity/buyInTime)+1-nextToMature)*buyInTime);
		_;
	}


	constructor(uint _buyInTime, uint _poolMaturity, uint _buyInPrice, 
address _tokenAddress, address _oracle, bytes32 _jobId, address _linkAddr=address(0)) public {
		buyInTime = _buyInTime;
		poolMaturity = _poolMaturity;
		buyInPrice = _buyInPrice;
		tokenAddress = _tokenAddress;
		admin = msg.sender;
		// startTime = block.number;
		startTime = now;
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
		Chainlink.request memory req = buildChainlinkRequest(chainlinkJobId, address(this), this.payOut.selector);
		req.addUint("until", getMaturity());
		sendChainlinkRequestTo(chainlinkOracle, req, chainlinkPayment);
	}

	function payOut() public poolIsMature {
		allPools[nextToMature].reset(tokenAddress);
		nextToMature = uint8((nextToMature + 1) % uint(poolMaturity/buyInTime + 1));
		if (nextToMature == 0)
			startTime += (uint(poolMaturity/buyInTime) + 1) * buyInTime;
		Chainlink.request memory req = buildChainlinkRequest(chainlinkJobId, address(this), this.payOut.selector);
		req.addUint("until", getMaturity());
		sendChainlinkRequestTo(chainlinkOracle, req, chainlinkPayment);
	}
		
	function getCurrentPool() public view returns (address) {
		return address(allPools[ uint8((now - startTime)/buyInTime) ]);
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
