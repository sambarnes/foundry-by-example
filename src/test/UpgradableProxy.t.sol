// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {UpgradableProxy} from "../UpgradableProxy.sol";

contract V1 {
    // Must share base storage layout with UpgradableProxy.
    // Thus, the implementation address must be specified here.
    address public implementation;

    // Custom functionality can be declared after though.
    uint256 public x;

    function inc() external virtual {
        x += 1;
    }
}

// Inherit from V1 to help avoid storage layout conflicts with V1.
// Override functionality we want to replace.
contract V2 is V1 {
    function inc() external virtual override {
        x += 2;
    }

    function dec() external virtual {
        x -= 2;
    }
}

contract UpgradableProxyTest is DSTestPlus {
    UpgradableProxy private upgradableContract;
    V1 private someOldContract;
    V2 private someNewContract;

    function setUp() public {
        upgradableContract = new UpgradableProxy();
        someOldContract = new V1();
        someNewContract = new V2();
    }

    function testV1() public {
        upgradableContract.setImplementation(address(someOldContract));
        assertEq(upgradableContract.implementation(), address(someOldContract));

        // Cast the UpgradableProxy to a V1 contract
        V1 ourContract = V1(address(upgradableContract));
        ourContract.inc();
        assertEq(ourContract.x(), 1);
        ourContract.inc();
        assertEq(ourContract.x(), 2);
    }

    function testV2BeforeUpgrade() public {
        upgradableContract.setImplementation(address(someOldContract));

        // Still only on V1, but mistakenly using V2 API
        V2 ourContract = V2(address(upgradableContract));

        // First call works because of shared func signatures
        ourContract.inc();
        assertEq(ourContract.x(), 1);

        // New call breaks tho
        vm.expectRevert(bytes(""));
        ourContract.dec();
    }

    function testV1ThenV2() public {
        upgradableContract.setImplementation(address(someOldContract));
        V1 ourContract = V1(address(upgradableContract));
        ourContract.inc();
        assertEq(ourContract.x(), 1);

        upgradableContract.setImplementation(address(someNewContract));
        V2 ourContractUpgraded = V2(address(upgradableContract));

        /*
        Previous state changes still seen in new contract!

        TIL: https://ethereum.stackexchange.com/a/79929
        " It might be cognitively useful to think of the proxy contract importing
        bytecode from the logic contracts for its own use because they execute in
        the context of the proxy and use the proxy for storage. "
        */
        assertEq(ourContractUpgraded.x(), 1);

        // New state changes have a delta of 2
        ourContractUpgraded.inc();
        assertEq(ourContractUpgraded.x(), 3);
        ourContractUpgraded.dec();
        assertEq(ourContractUpgraded.x(), 1);
    }
}
