// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {Storage} from "../WriteToAnySlot.sol";

contract StorageTest is DSTestPlus {
    Storage private s;

    function setUp() public {
        s = new Storage();
    }

    function testSetAndGetWithinBounds() public {
        // Should set slots within known bounds of the declared structs
        s.set(0, 123);
        assertEq(s.s0(), 123);
        assertEq(s.get(0), 123);

        s.set(1, 456);
        assertEq(s.s1(), 456);
        assertEq(s.get(1), 456);

        s.set(2, 789);
        assertEq(s.s2(), 789);
        assertEq(s.get(2), 789);
    }

    function testSetAndGetOutsideBounds() public {
        // Should set slots outside known bounds of the declared structs
        s.set(17, 123);
        assertEq(s.get(17), 123);

        s.set(42, 456);
        assertEq(s.get(42), 456);

        s.set(999, 789);
        assertEq(s.get(999), 789);
    }

    function testGetWithStoreCheatcode() public {
        // An excuse to try out the vm.store cheatcode
        vm.store(address(s), bytes32(uint256(0)), bytes32(uint256(123)));
        // Both accessors now point to that data!
        assertEq(s.s0(), 123);
        assertEq(s.get(0), 123);
    }
}
