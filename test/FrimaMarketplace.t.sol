// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {FrimaNFT} from "../src/FrimaNFT.sol";
import {FrimaMarketplace} from "../src/FrimaMarketplace.sol";

contract FrimaMarketplaceTest is Test {
    FrimaNFT public nft;
    FrimaMarketplace public marketplace;

    address public seller = address(1);
    address public buyer = address(2);

    function setUp() public {
        nft = new FrimaNFT();
        marketplace = new FrimaMarketplace(address(nft));
        nft.setFrimaMarketplace(address(marketplace));
    }

    function test_ListItem() public {
        vm.prank(seller);
        uint256 itemId = marketplace.listItem(
            "Test Item",
            1 ether,
            "This is a test item",
            "https://example.com/image.png",
            "user123",
            "Electronics",
            "ipfs://test"
        );

        assertEq(itemId, 1);

        FrimaMarketplace.Item memory item = marketplace.getItem(1);
        assertEq(item.title, "Test Item");
        assertEq(item.price, 1 ether);
        assertEq(item.explanation, "This is a test item");
        assertEq(item.imageUrl, "https://example.com/image.png");
        assertEq(item.uid, "user123");
        assertEq(item.category, "Electronics");
        assertEq(item.isPurchased, false);
        assertEq(item.seller, seller);
    }

    function test_BuyItem() public {
        vm.prank(seller);
        marketplace.listItem(
            "Test Item",
            1 ether,
            "This is a test item",
            "https://example.com/image.png",
            "user123",
            "Electronics",
            "ipfs://test"
        );

        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        marketplace.buyItem{value: 1 ether}(1);

        FrimaMarketplace.Item memory item = marketplace.getItem(1);
        assertEq(item.isPurchased, true);
        assertEq(item.buyer, buyer);
        assertEq(uint256(item.status), uint256(FrimaMarketplace.Status.Purchased));
    }

    function test_BuyItemWithExcessPayment() public {
        vm.prank(seller);
        marketplace.listItem(
            "Test Item",
            1 ether,
            "This is a test item",
            "https://example.com/image.png",
            "user123",
            "Electronics",
            "ipfs://test"
        );

        vm.deal(buyer, 3 ether);
        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(buyer);
        marketplace.buyItem{value: 2 ether}(1);

        // 過払い分(1 ether)が返金されているか確認
        assertEq(buyer.balance, buyerBalanceBefore - 1 ether);
    }

    function test_ConfirmReceipt() public {
        vm.prank(seller);
        marketplace.listItem(
            "Test Item",
            1 ether,
            "This is a test item",
            "https://example.com/image.png",
            "user123",
            "Electronics",
            "ipfs://test"
        );

        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        marketplace.buyItem{value: 1 ether}(1);

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        marketplace.confirmReceipt(1);

        FrimaMarketplace.Item memory item = marketplace.getItem(1);
        assertEq(uint256(item.status), uint256(FrimaMarketplace.Status.Completed));
        assertEq(seller.balance, sellerBalanceBefore + 1 ether);
    }

    function test_CancelListing() public {
        vm.prank(seller);
        marketplace.listItem(
            "Test Item",
            1 ether,
            "This is a test item",
            "https://example.com/image.png",
            "user123",
            "Electronics",
            "ipfs://test"
        );

        vm.prank(seller);
        marketplace.cancelListing(1);

        FrimaMarketplace.Item memory item = marketplace.getItem(1);
        assertEq(uint256(item.status), uint256(FrimaMarketplace.Status.Cancelled));
    }

    function test_UpdateItem() public {
        vm.prank(seller);
        marketplace.listItem(
            "Test Item",
            1 ether,
            "This is a test item",
            "https://example.com/image.png",
            "user123",
            "Electronics",
            "ipfs://test"
        );

        vm.prank(seller);
        marketplace.updateItem(
            1,
            "Updated Item",
            2 ether,
            "Updated description",
            "https://example.com/new-image.png",
            "Fashion"
        );

        FrimaMarketplace.Item memory item = marketplace.getItem(1);
        assertEq(item.title, "Updated Item");
        assertEq(item.price, 2 ether);
        assertEq(item.explanation, "Updated description");
        assertEq(item.category, "Fashion");
    }

    function test_RevertWhen_BuyOwnItem() public {
        vm.prank(seller);
        marketplace.listItem(
            "Test Item",
            1 ether,
            "This is a test item",
            "https://example.com/image.png",
            "user123",
            "Electronics",
            "ipfs://test"
        );

        vm.deal(seller, 2 ether);
        vm.prank(seller);
        vm.expectRevert("Seller cannot buy their own item.");
        marketplace.buyItem{value: 1 ether}(1);
    }

    function test_RevertWhen_CancelByNonSeller() public {
        vm.prank(seller);
        marketplace.listItem(
            "Test Item",
            1 ether,
            "This is a test item",
            "https://example.com/image.png",
            "user123",
            "Electronics",
            "ipfs://test"
        );

        vm.prank(buyer);
        vm.expectRevert("Only seller can cancel listing.");
        marketplace.cancelListing(1);
    }

    function test_RevertWhen_ConfirmReceiptByNonBuyer() public {
        vm.prank(seller);
        marketplace.listItem(
            "Test Item",
            1 ether,
            "This is a test item",
            "https://example.com/image.png",
            "user123",
            "Electronics",
            "ipfs://test"
        );

        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        marketplace.buyItem{value: 1 ether}(1);

        vm.prank(seller);
        vm.expectRevert("Only buyer can confirm receipt.");
        marketplace.confirmReceipt(1);
    }
}
