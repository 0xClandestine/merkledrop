# 🪄Merkledrop

Merkledrop allows anyone to mass distribute tokens for 135k gas.

## Deployments

-  [Goerli](https://goerli.etherscan.io/address/0x240009354c9302776970918eBD0677bCe3B43F4A)
-  [Mainet](https://etherscan.io/address/0xB7113FF8F7a56403cEdF02fF103B57F3E6FABd3D)


## Architecture

-   [`Merkledrop.sol`](src/Merkledrop.sol): `Merkledrop` allows anyone to mass distribute large tokens for 135k gas.
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
