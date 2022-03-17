// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {MerkleTree} from "../MerkleTree.sol";

contract MerkleTreeTest is DSTestPlus {
    MerkleTree private merkle;
    bytes32[] private hashes;

    bytes32[] private someProof;

    function setUp() public {
        merkle = new MerkleTree();

        // Given a list of transactions
        string[4] memory transactions = [
            "alice -> bob",
            "bob -> dave",
            "carol -> alice",
            "dave -> bob"
        ];
        // ... hash every element for the tree
        for (uint256 i = 0; i < transactions.length; i++) {
            hashes.push(keccak256(abi.encodePacked(transactions[i])));
        }

        // Hash individual element hashes together to form the tree
        uint256 n = transactions.length;
        uint256 offset = 0;
        while (n > 0) {
            for (uint256 i = 0; i < n - 1; i += 2) {
                hashes.push(
                    keccak256(
                        abi.encodePacked(
                            hashes[offset + i],
                            hashes[offset + i + 1]
                        )
                    )
                );
            }
            offset += n;
            n = n / 2;
        }

        // Shortcut: initialize some valid proof
        someProof.push(
            0x948f90037b4ea787c14540d9feb1034d4a5bc251b9b5f8e57d81e4b470027af8
        );
        someProof.push(
            0x63ac1b92046d474f84be3aa0ee04ffe5600862228c81803cce07ac40484aee43
        );
    }

    // More shortcuts
    bytes32 thirdLeaf =
        0x1bbd78ae6188015c4a6772eb1526292b5985fc3272ead4c65002240fb9ae5d13;
    bytes32 root =
        0x074b43252ffb4a469154df5fb7fe4ecce30953ba8b7095fe1e006185f017ad10;

    function testVerify() public {
        bool result = merkle.verify(someProof, root, thirdLeaf, 2);
        assertTrue(result);
    }

    function testVerifyBadIndex() public {
        // Should be index 2
        bool result = merkle.verify(someProof, root, thirdLeaf, 0);
        assertTrue(result == false);
    }

    function testVerifyBadProof() public {
        someProof[0] = 0x0;
        bool result = merkle.verify(someProof, root, thirdLeaf, 2);
        assertTrue(result == false);
    }
}
