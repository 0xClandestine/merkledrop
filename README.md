# 🪄Merkledrop

Merkledrop allows anyone to mass distribute large amounts of tokens for only 100k gas.

## Deployments

-   [`MerkledropFactory.sol`](src/MerkledropFactory.sol): [Goerli](https://goerli.etherscan.io/address/0x7a325031c4F83C87B2165E58cef53e8C9956E973)

## Architecture

-   [`Merkledrop.sol`](src/Merkledrop.sol): `Merkledrop` allows anyone to mass distribute large amounts of tokens for only 100k gas.
-   [`MerkledropFactory.sol`](src/MerkledropFactory.sol): Minimal proxy factory that creates `Merkledrop` clones.

## Installation

To install with [Foundry](https://github.com/gakonst/foundry):

```
forge install 0xClandestine/merkledrop
```

## Local development

This project uses [Foundry](https://github.com/gakonst/foundry) as the development framework.

### Dependencies

```
forge install
```

### Compilation

```
forge build
```

### Testing

```
forge test
```
