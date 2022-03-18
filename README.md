<img align="right" width="150" height="150" top="100" src="./assets/readme.jpg">

# foundry-by-example • [![tests](https://github.com/sambarnes/foundry-by-example/actions/workflows/tests.yml/badge.svg)](https://github.com/sambarnes/foundry-by-example/actions/workflows/tests.yml) [![lints](https://github.com/sambarnes/foundry-by-example/actions/workflows/lints.yml/badge.svg)](https://github.com/sambarnes/foundry-by-example/actions/workflows/lints.yml) ![GitHub](https://img.shields.io/github/license/sambarnes/foundry-by-example)  ![GitHub package.json version](https://img.shields.io/github/package-json/v/sambarnes/foundry-by-example)


This repo is my personal onramp to [foundry](https://github.com/gakonst/foundry) -- a testing setup for solidity. The applications at [solidity-by-example](https://solidity-by-example.org/) are simple & some have no tests, so I'm re-writing it in foundry as an exercise.

Covered so far:
* [EtherWallet](https://solidity-by-example.org/app/ether-wallet/) ([EtherWallet.t.sol](./src/test/EtherWallet.t.sol)) - basic `assertEq` and `vm.expectRevert`
* [MerkleTree](https://solidity-by-example.org/app/merkle-tree/) ([MerkleTree.t.sol](./src/test/MerkleTree.t.sol)) - also super basic
* [EnglishAuction](https://solidity-by-example.org/app/english-auction/) ([EnglishAuction.t.sol](./src/test/EnglishAuction.t.sol)) - `vm.prank` (account impersonation), `vm.deal` (mock balances), and `vm.warp` (mock block timestamp)
* [DutchAuction](https://solidity-by-example.org/app/dutch-auction/) ([DutchAuction.t.sol](./src/test/DutchAuction.t.sol)) - also basic
* [MultiCall](https://solidity-by-example.org/app/multi-call/) ([MultiCall.t.sol](./src/test/MultiCall.t.sol)) - this was straightforward and easy too, noticing a trend
* [UpgradableProxy](https://solidity-by-example.org/app/upgradeable-proxy/) ([UpgradableProxy.t.sol](./src/test/UpgradableProxy.t.sol)) - ezpz, the only interesting part here was learning how cool the proxy pattern is (shared storage between impl, but new code to execute against it? 🤯)
* [WriteToAnySlot](https://solidity-by-example.org/app/write-to-any-slot/) ([WriteToAnySlot.t.sol](./src/test/WriteToAnySlot.t.sol)) - an excuse to try the `vm.store` cheatcode to put mock out storage slots
* _TODO: more_


## Development

**Building**
```bash
make build
```

**Testing**
```bash
make test
```

### First time with Forge/Foundry?

See the official Foundry installation [instructions](https://github.com/gakonst/foundry/blob/master/README.md#installation).

Then, install the [foundry](https://github.com/gakonst/foundry) toolchain installer (`foundryup`) with:
```bash
curl -L https://foundry.paradigm.xyz | bash
```

Now that you've installed the `foundryup` binary,
anytime you need to get the latest `forge` or `cast` binaries,
you can run `foundryup`.

So, simply execute:
```bash
foundryup
```

🎉 Foundry is installed! 🎉

### Writing Tests with Foundry

With [Foundry](https://gakonst.xyz), tests are written in Solidity! 🥳

Create a test file for your contract in the `src/tests/` directory.

For example, [`src/Greeter.sol`](./src/Greeter.sol) has its test file defined in [`./src/tests/Greeter.t.sol`](./src/tests/Greeter.t.sol).

To learn more about writing tests in Solidity for Foundry and Dapptools, reference Rari Capital's [solmate](https://github.com/Rari-Capital/solmate/tree/main/src/test) repository largely created by [@transmissions11](https://twitter.com/transmissions11).

### Configure Foundry

Using [foundry.toml](./foundry.toml), Foundry is easily configurable.

For a full list of configuration options, see the Foundry [configuration documentation](https://github.com/gakonst/foundry/blob/master/config/README.md#all-options).


## Acknowledgements

- [femplate](https://github.com/abigger87/femplate)
- [foundry](https://github.com/gakonst/foundry)
- [solmate](https://github.com/Rari-Capital/solmate)
- [forge-std](https://github.com/brockelmore/forge-std)
- [clones-with-immutable-args](https://github.com/wighawag/clones-with-immutable-args).
- [foundry-toolchain](https://github.com/onbjerg/foundry-toolchain) by [onbjerg](https://github.com/onbjerg).
- [forge-template](https://github.com/FrankieIsLost/forge-template) by [FrankieIsLost](https://github.com/FrankieIsLost).
- [Georgios Konstantopoulos](https://github.com/gakonst) for [forge-template](https://github.com/gakonst/forge-template) resource.

## Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._
