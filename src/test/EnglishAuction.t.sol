// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {ERC721} from "@openzeppelin/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "@openzeppelin/token/ERC721/IERC721Receiver.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {EnglishAuction} from "../EnglishAuction.sol";

contract SomeNFT is ERC721 {
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function mint(uint256 tokenId) external payable {
        _mint(msg.sender, tokenId);
    }
}

contract EnglishAuctionTest is IERC721Receiver, DSTestPlus {
    SomeNFT private nft;
    EnglishAuction private auction;

    uint256 private someTokenId = 0;
    uint256 private startingBid = 1 ether;

    address private someBuyer = vm.addr(123);
    address private someOtherBuyer = vm.addr(456);
    uint256 private someStartingBalance = 100 ether;

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setUp() public {
        vm.deal(someBuyer, someStartingBalance);
        vm.deal(someOtherBuyer, someStartingBalance);

        nft = new SomeNFT("Good Mornings", "GM");
        nft.mint(someTokenId);

        auction = new EnglishAuction(address(nft), someTokenId, startingBid);
        nft.approve(address(auction), someTokenId);
    }

    function testStartNotSeller() public {
        vm.expectRevert(bytes("not seller"));
        vm.prank(someBuyer);
        auction.start();
    }

    function testStart() public {
        assertTrue(auction.started() == false);
        assertEq(nft.ownerOf(someTokenId), address(this));

        auction.start();
        assertTrue(auction.started());
        assertEq(auction.seller(), address(this));
        assertEq(nft.ownerOf(someTokenId), address(auction));
        assertEq(auction.highestBid(), startingBid);
    }

    function testStartAlreadyStarted() public {
        auction.start();
        vm.expectRevert(bytes("started"));
        auction.start();
    }

    function testBidNotStarted() public {
        vm.expectRevert(bytes("not started"));
        vm.prank(someBuyer);
        auction.bid{value: startingBid * 2}();
    }

    function testBidAuctionEnded() public {
        auction.start();
        vm.warp(auction.endAt() + 1 days);

        vm.expectRevert(bytes("ended"));
        vm.prank(someBuyer);
        auction.bid{value: startingBid * 2}();
    }

    function testBidLowballOffer() public {
        auction.start();

        vm.expectRevert(bytes("value < highest"));
        vm.prank(someBuyer);
        auction.bid{value: startingBid / 2}();
    }

    function testBid() public {
        auction.start();

        uint256 someBid = startingBid * 2;
        vm.prank(someBuyer);
        auction.bid{value: someBid}();

        assertEq(auction.highestBid(), someBid);
        assertEq(auction.highestBidder(), someBuyer);
        assertEq(auction.bids(someBuyer), 0); // don't set bids map until outbid
        assertEq(someBuyer.balance, someStartingBalance - someBid);
        assertEq(address(auction).balance, someBid);
    }

    function testTwoBids() public {
        auction.start();

        uint256 someBid = startingBid * 2;
        vm.prank(someBuyer);
        auction.bid{value: someBid}();

        uint256 someOtherBid = startingBid * 3;
        vm.prank(someOtherBuyer);
        auction.bid{value: someOtherBid}();

        // Newest bid now on top & both bids still in contract
        assertEq(auction.highestBid(), someOtherBid);
        assertEq(auction.highestBidder(), someOtherBuyer);
        assertEq(address(auction).balance, someBid + someOtherBid);

        // Original bidder now has a recorded bid amount, but not new bidder
        assertEq(auction.bids(someBuyer), someBid);
        assertEq(auction.bids(someOtherBuyer), 0);
    }

    function testWithdrawHighestBid() public {
        auction.start();

        uint256 someBid = startingBid * 2;
        vm.startPrank(someBuyer);
        auction.bid{value: someBid}();
        auction.withdraw();

        // Balance should still be in contract, since it's the highest bid
        assertEq(address(auction).balance, someBid);
        assertEq(someBuyer.balance, someStartingBalance - someBid);
    }

    function testWithdraw() public {
        auction.start();

        uint256 someBid = startingBid * 2;
        vm.prank(someBuyer);
        auction.bid{value: someBid}();

        uint256 someOtherBid = startingBid * 3;
        vm.prank(someOtherBuyer);
        auction.bid{value: someOtherBid}();

        vm.prank(someBuyer);
        auction.withdraw();

        // Bid zeroed out and ETH sent back to someBuyer
        assertEq(auction.bids(someBuyer), 0);
        assertEq(someBuyer.balance, someStartingBalance);
        assertEq(address(auction).balance, someOtherBid);
    }

    function testEndNotStarted() public {
        vm.expectRevert(bytes("not started"));
        auction.end();
    }

    function testEndTooEarly() public {
        auction.start();
        vm.expectRevert(bytes("not ended"));
        auction.end();
    }

    function testEndNoBids() public {
        auction.start();
        vm.warp(auction.endAt());
        auction.end();

        assertEq(nft.ownerOf(someTokenId), address(this)); // regain ownership
    }

    function testEnd() public {
        auction.start();
        uint256 sellerStartingBalance = address(this).balance;

        uint256 someBid = startingBid * 2;
        vm.startPrank(someBuyer);
        auction.bid{value: someBid}();

        vm.warp(auction.endAt());
        auction.end();

        assertTrue(auction.ended());
        assertEq(nft.ownerOf(someTokenId), someBuyer);
        assertEq(someBuyer.balance, someStartingBalance - someBid);
        assertEq(address(auction).balance, 0);
        assertEq(address(this).balance, sellerStartingBalance + someBid);
    }

    function testEndAgain() public {
        auction.start();

        vm.warp(auction.endAt());
        auction.end();
        vm.expectRevert(bytes("ended"));
        auction.end();
    }

    function testWithdrawLoserAfterEnd() public {
        auction.start();
        uint256 sellerStartingBalance = address(this).balance;

        uint256 someBid = startingBid * 2;
        vm.prank(someBuyer);
        auction.bid{value: someBid}();

        uint256 someOtherBid = startingBid * 3;
        vm.prank(someOtherBuyer);
        auction.bid{value: someOtherBid}();

        vm.warp(auction.endAt());
        auction.end();
        assertEq(address(this).balance, sellerStartingBalance + someOtherBid);

        // Loser withdraws
        vm.prank(someBuyer);
        auction.withdraw();

        // Losing bid zeroed out and ETH sent back
        assertEq(auction.bids(someBuyer), 0);
        assertEq(someBuyer.balance, someStartingBalance);

        // Because winning bid sent to seller, should have nothing left
        assertEq(address(auction).balance, 0);
    }
}
