// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FrimaNFT} from "../src/FrimaNFT.sol";
import {FrimaMarketplace} from "../src/FrimaMarketplace.sol";

contract FrimaMarketplaceScript is Script {
    FrimaNFT public nft;
    FrimaMarketplace public marketplace;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 1. NFTコントラクトをデプロイ
        nft = new FrimaNFT();
        console.log("FrimaNFT deployed at:", address(nft));

        // 2. マーケットプレイスコントラクトをデプロイ
        marketplace = new FrimaMarketplace(address(nft));
        console.log("FrimaMarketplace deployed at:", address(marketplace));

        // 3. NFTコントラクトにマーケットプレイスアドレスを設定
        nft.setFrimaMarketplace(address(marketplace));
        console.log("FrimaMarketplace address set in FrimaNFT");

        vm.stopBroadcast();

        // デプロイ情報のサマリー
        console.log("========================================");
        console.log("Deployment Summary:");
        console.log("FrimaNFT:         ", address(nft));
        console.log("FrimaMarketplace: ", address(marketplace));
        console.log("========================================");
    }
}
