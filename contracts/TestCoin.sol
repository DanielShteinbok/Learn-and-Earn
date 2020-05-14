
// as always, modify the import path below to import ERC20.sol by OpenZeppelin on your machine.
import "../../openzeppelin/node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestCoin is ERC20 ("Test Coin", "T") {
	constructor() public {
		_mint(msg.sender, 10000);
	}
}
