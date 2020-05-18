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
### Catching the event at the time a person pays to a pool
## Recording that someone has completed a course
