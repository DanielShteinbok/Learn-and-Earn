pragma solidity >=0.4.21 < 0.7.0;

// below, the import path is relative to my own directory structure/inability to import
// npm-installed openzeppelin contracts properly.
// You will probably have to modify the import path to import IERC20.sol from OpenZeppelin on your machine.

// import OpenZeppelin's IERC20.sol
import "../../openzeppelin/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import LendingPoolAddressesProvider.sol
import "../../flashloan-box/contracts/aave/ILendingPoolAddressesProvider.sol";
// import LendingPool.sol
import "../../flashloan-box/contracts/aave/ILendingPool.sol";
// import aToken.sol
import "./IAToken.sol";

contract SinglePool {
	address public admin;
	address courseContract;
	mapping (address => address) private completed;
	address private lastCompleted;
	uint public numberCompleted = 0;
	
	modifier adminOnly {
                require (msg.sender == admin);
                _;
        }
	
	modifier courseContractOnly {
		require (msg.sender == courseContract);
		_;
	}
	
	constructor(address _admin) public {
		admin = _admin;
		courseContract = msg.sender;
	}
	
	function addCompleter( address completer ) public adminOnly {
                if ( numberCompleted != 0 )
                        completed[completer] = lastCompleted;
                lastCompleted = completer;
                ++numberCompleted;
        }
	function invest(address tokenAddress, address lendingPoolProvider) public courseContractOnly {
		IERC20 token = IERC20(tokenAddress);
		ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(lendingPoolProvider);
		token.approve(provider.getLendingPoolCore(), token.balanceOf(address(this)));
		ILendingPool(provider.getLendingPool()).deposit(tokenAddress, token.balanceOf(address(this)), 0);
	}
	
	function reset(address tokenAddress, address aTokenAddr) public courseContractOnly {
		IAToken aaveToken = IAToken(aTokenAddr);
		aaveToken.redeem(aaveToken.balanceOf(address(this)));
		IERC20 token = IERC20(tokenAddress);
		if (numberCompleted != 0) {
			uint payOutAmount = token.balanceOf(address(this)) / numberCompleted;
			address giveTo = lastCompleted;
			while (giveTo != address(0)) {
				token.transfer(giveTo, payOutAmount);
				giveTo = completed[giveTo];
			}
			numberCompleted = 0;
		}
		token.transfer(admin, token.balanceOf(address(this))); 
		lastCompleted = address(0);
	}
	
	function getAdmin() public view returns (address) {
		return admin;
	}
}
