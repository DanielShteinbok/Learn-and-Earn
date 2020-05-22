pragma solidity ^0.6.0;

interface IAToken {
	function redeem(uint256 _amount) external;
	function balanceOf(address account) external view returns (uint256);
}
