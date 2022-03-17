// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {ERC721} from "@openzeppelin/token/ERC721/ERC721.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {DutchAuction} from "../DutchAuction.sol";

contract SomeNFT is ERC721 {
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function mint(uint256 tokenId) external payable {
        _mint(msg.sender, tokenId);
    }
}

contract DutchAuctionTest is DSTestPlus {
    SomeNFT private nft;
    DutchAuction private auction;

    uint256 private someTokenId = 0;
    uint256 private startingPrice = 100 ether;
    uint256 private discountRate = 0.0001 ether;

    address private someBuyer = vm.addr(123);
    uint256 private someStartingBalance = 300 ether;

    receive() external payable {}

    function setUp() public {
        vm.deal(someBuyer, someStartingBalance);

        nft = new SomeNFT("Good Mornings", "GM");
        nft.mint(someTokenId);

        auction = new DutchAuction(
            startingPrice,
            discountRate,
            address(nft),
            someTokenId
        );
        nft.approve(address(auction), someTokenId);
    }

    function testConstructor() public {
        assertEq(auction.seller(), address(this));
        assertEq(auction.startingPrice(), startingPrice);
        assertEq(auction.discountRate(), discountRate);
        assertEq(address(auction.nft()), address(nft));
        assertEq(auction.nftId(), someTokenId);
    }

    function testBuyAuctionExpired() public {
        vm.warp(auction.expiresAt() + 1 days);
        vm.expectRevert(bytes("auction expired"));
        vm.prank(someBuyer);
        auction.buy{value: startingPrice}();
    }

    function testBuyLowballOffer() public {
        vm.expectRevert(bytes("ETH < price"));
        vm.prank(someBuyer);
        auction.buy{value: startingPrice / 2}();
    }

    function testBuy() public {
        uint256 sellerStartingBalance = address(this).balance;

        vm.prank(someBuyer);
        auction.buy{value: startingPrice}();

        // Buyer has less eth but owns nft
        assertEq(someBuyer.balance, someStartingBalance - startingPrice);
        assertEq(nft.ownerOf(someTokenId), someBuyer);

        // Contract has no balance, and seller has
        assertEq(address(auction).balance, 0);
        assertEq(address(this).balance, sellerStartingBalance + startingPrice);
    }

    function testBuyAndRefundExcess() public {
        uint256 sellerStartingBalance = address(this).balance;

        vm.prank(someBuyer);
        auction.buy{value: startingPrice * 2}(); // Send twice as much as needed

        // Still a successful purchase & transfer
        assertEq(nft.ownerOf(someTokenId), someBuyer);

        // ... but only startingPrice deducted
        assertEq(someBuyer.balance, someStartingBalance - startingPrice);

        // ... and seller also only gets the startingPrice
        assertEq(address(this).balance, sellerStartingBalance + startingPrice);
    }

    function testGetPrice() public {
        assertEq(auction.getPrice(), startingPrice);
        vm.warp(auction.startAt() + 2 days);
        assertEq(auction.getPrice(), startingPrice - (discountRate * 2 days));
    }
}
