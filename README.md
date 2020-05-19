# Learn and Earn
These are the smart contracts that form the blockchain component of the Learn and Earn smart contract, as well as some truffle scripts for testing and migrations. Below, you will find instructions on interacting with the smart contracts via javascript.
It is assumed that you have a `course` truffle-contract object (i.e. created via `const course = await Course.deployed()` using truffle's truffle-contract library, where `Course` is the JSON blob associated with a compiled `contracts/Course.sol`.
It is up to the utilizing dapp's back-end to keep track of `Course` contract addresses, but all the pools for a single `Course` will be managed by that `Course` contract, and can be interacted with as shown below.

## Get all pool addresses for a Course
To find out whether a person has staked in a course, and what pool that stake was in, it is necessary to know the addresses of all the pools associated with a Course (so it is possible to filter event logs appropriately). A course contract does not expose a function that will return all related pools simultaneously. However, the contract does expose an auto-generated getter function for a mapping `(uint8 => SinglePool)`. The pools are referenced by consecutive values from 0 to one less than the number of pools; it is thus possible to iterate through them, if you know how many pools there are. To calculate this, one can do the following:

### Calculate the number of pools
The number of pools is calculated algorithmically as `ceiling(maturityPeriod/buyInPeriod)`. In javascript, to get the number of pools associated with `course`, one could do the following:

```javascript
var numberPools = await course.poolMaturity();
numberPools /= await course.buyInTime();
numberPools = Math.floor(numberPools);
++numberPools; 
/* Math.floor and ++numberPools is an implementation that mimics the ceiling() logical function, while ensuring that even in the case of the maturityPeriod being divisible by the buyInPeriod, the number of pools is one greater than the result of that division, because this a) is constistent with what the smart contract does, and b) ensures that there is always a window within which the the the buy-in period of any pool can end safely. */
```

### Getting pool addresses
To get the pool at a single index, `Course` exposes `function getPoolByIndex (uint8 poolIndex) public view returns (address)`, which takes in an index and returns the address of the appropriate SinglePool contract. In truffle-contract, accessing this should be as simple as:
```javascript
course.getPoolByIndex(x);
```
With a web3 contract, this should be possible via:
```javascript
course.methods.getPoolByIndex(x);
```
Instead of iterating by pool number, it is also possible to simply iterate until the function returns a zero address, since all addresses are indexed contiguously from 0. For example, one could do this:
```javascript
var poolAddress;
for (var i=0; course.getPoolByIndex(i) != '0x0000000000000000000000000000000000000000'; ++i) {
	poolAddress = course.getPoolByIndex(i);
	// do stuff
}
```
## Checking whether a person has paid to a pool
The only way that a person "enrols" in a course is by transfering some ERC20 tokens to one of those course's pools. It then becomes possible to verify that that person is enrolled outside of a smart contract, by verifying the "Transfer" event that is emitted by the ERC20 token. The easiest way to handle people enroling is to catch the "Transfer" events when they occur, and then verify in the back end that that person is eligible to enroll and marking it down in the back end, so that further repeated references to the blockchain are unnecessary.
### Catching the event at the time a person pays to a pool
To catch events as they occur, one can employ the web3 function `myContract.events.MyEvent([options][, callback])`. Specifically, to see if a user has staked into a course:
1. Get an array of pool addresses (see "Getting pool addresses" above). Suppose this array is called `poolsArray`.
2. Given the variable referencing the ERC20 contract is called `token`, subscribe to all "Transfer" events to all pool addresses with the following:
```javascript
token.events.Transfer({
	filter: { to: poolsArray },
	fromBlock: 0
}).on("data", function (event) {
	if (event.returnValues.value < await course.buyInPrice()) {
		// handle insufficient funds
		return;
	}
	if (event.returnValues.to != await course.getCurrentPool()) {
		// handle person submitting to incorrect pool
		// note: the event may not be received at the same time that it 
		// was submitted; therefore, there should be some checking with
		// event.blockNumber or something instead of just checking at the time
		// of reception. I am still working on this.
		return;
	}
	// handle good case, where person is submitting to correct pool
	// at correct time.
});
```
note above that simply passing an array of addresses functions as a logical OR between all of them. Since pools are never destroyed, only reset and recycled, the addresses never change and this is safe to do.
### Catching events retroactively
In the event that, for some reason, a person's "Transfer" event is not caught at the right time by the server, the event remains immutable on the blockchain. So, for example if a person submits a test but their address is not found in the database, it is possible to check for past events via the web3 function: `myContract.getPastEvents(event[, options][, callback])`. For example, with the objects described above, as well as the address `tokenSender` of the person we are checking:
```javascript
token.getPastEvents("Transfer", {filter: {
		to: poolsArray,
		from: tokenSender
	}
	fromBlock: 0,
	toBlock: "latest"
}).on("data", function (event) {
	// handle stuff appropriately
});
```
## Recording that someone has completed a course
To record that someone has completed a course, it is necessary to interact directly with the appropriate pool contract. This decision was made because the appropriate pool can only reliably be selected based on the events, which are only accessible off-chain anyway. Thus, given the appropriate pool address `poolAddress`, one must directly create a pool object via the SinglePool ABI. The exact syntax varies between Web3 and truffle-contract. for Web3, one can use the "new" keyword, as per https://web3js.readthedocs.io/en/v1.2.0/web3-eth-contract.html. for truffle-contract, see https://www.npmjs.com/package/truffle-contract. 
given the `pool` object, add an address to the list of completers with:
```javascript
// for truffle-contract
pool.addCompleter(completerAddress);

// for web3
pool.methods.addCompleter(completerAddress).send({from: <admin address here>});
```
note that the `addCompleter` method can only be called by the same address that deployed the `Course` contract (called the "admin" address, for lack of a better term).

