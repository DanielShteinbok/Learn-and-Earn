pragma solidity ^0.6.0;
// import "../../openzeppelin/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAToken /*is IERC20*/ {
	function redeem(uint256 _amount) external;
	function balanceOf(address account) external view returns (uint256);
}
