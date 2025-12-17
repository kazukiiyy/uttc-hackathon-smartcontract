// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FrimaNFT} from "./FrimaNFT.sol";

contract FrimaMarketplace {
    FrimaNFT public nftContract;

    enum Status {
        Listed,
        Purchased,
        Completed,
        Cancelled
    }

    struct Item {
        uint256 itemId;
        uint256 tokenId;
        string title;
        uint256 price;
        string explanation;
        string imageUrl;
        string uid;
        uint256 createdAt;
        uint256 updatedAt;
        bool isPurchased;
        string category;
        address payable seller;
        address payable buyer;
        Status status;
    }

    mapping(uint256 => Item) public items;
    uint256 public itemIdCounter = 1;

    // イベント定義
    event ItemListed(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed seller,
        string title,
        uint256 price,
        string explanation,
        string imageUrl,
        string uid,
        uint256 createdAt,
        string category
    );

    event ItemPurchased(
        uint256 indexed itemId,
        address indexed buyer,
        uint256 price,
        uint256 timestamp,
        uint256 tokenId
    );

    event ItemUpdated(
        uint256 indexed itemId,
        string title,
        uint256 price,
        string explanation,
        string imageUrl,
        string category,
        uint256 updatedAt
    );

    event ItemCancelled(
        uint256 indexed itemId,
        address indexed seller,
        uint256 timestamp
    );

    event ReceiptConfirmed(
        uint256 indexed itemId,
        address indexed buyer,
        address indexed seller,
        uint256 price,
        uint256 timestamp
    );

    constructor(address _nftContract) {
        nftContract = FrimaNFT(_nftContract);
    }

    /**
     * @notice 新しい商品のNFTを発行し、マーケットプレイスに出品する
     * @param _title 商品タイトル
     * @param _price 価格 (Wei単位)
     * @param _explanation 商品説明
     * @param _imageUrl 商品画像URL
     * @param _uid ユーザーID
     * @param _category カテゴリー
     * @param _tokenUri 商品メタデータ (IPFSハッシュなど)
     */
    function listItem(
        string memory _title,
        uint256 _price,
        string memory _explanation,
        string memory _imageUrl,
        string memory _uid,
        string memory _category,
        string memory _tokenUri
    ) public returns (uint256) {
        require(_price > 0, "Price must be greater than zero.");
        require(bytes(_title).length > 0, "Title cannot be empty.");

        uint256 newItemId = itemIdCounter;
        uint256 currentTime = block.timestamp;

        // NFTのミント
        nftContract.safeMint(msg.sender, newItemId, _tokenUri);

        // 出品情報の登録
        items[newItemId] = Item({
            itemId: newItemId,
            tokenId: newItemId,
            title: _title,
            price: _price,
            explanation: _explanation,
            imageUrl: _imageUrl,
            uid: _uid,
            createdAt: currentTime,
            updatedAt: currentTime,
            isPurchased: false,
            category: _category,
            seller: payable(msg.sender),
            buyer: payable(address(0)),
            status: Status.Listed
        });

        itemIdCounter++;

        // 出品通知イベント発行
        emit ItemListed(
            newItemId,
            newItemId,
            msg.sender,
            _title,
            _price,
            _explanation,
            _imageUrl,
            _uid,
            currentTime,
            _category
        );

        return newItemId;
    }

    /**
     * @notice 商品を購入する
     * @param _itemId 商品ID
     */
    function buyItem(uint256 _itemId) public payable {
        Item storage item = items[_itemId];

        require(item.itemId != 0, "Item does not exist.");
        require(item.status == Status.Listed, "Item is not available for purchase.");
        require(msg.value >= item.price, "Insufficient payment.");
        require(msg.sender != item.seller, "Seller cannot buy their own item.");

        // NFTの所有権移転
        nftContract.transferFrom(item.seller, msg.sender, item.tokenId);

        // 状態を「購入済み」に変更
        item.status = Status.Purchased;
        item.buyer = payable(msg.sender);
        item.isPurchased = true;
        item.updatedAt = block.timestamp;

        // 過払い分の返金
        uint256 excess = msg.value - item.price;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }

        // 通知イベントの発行
        emit ItemPurchased(
            _itemId,
            msg.sender,
            item.price,
            block.timestamp,
            item.tokenId
        );
    }

    /**
     * @notice 受け取り確認（エスクロー解除）
     * @param _itemId 商品ID
     */
    function confirmReceipt(uint256 _itemId) public {
        Item storage item = items[_itemId];

        require(item.status == Status.Purchased, "Item is not in purchased state.");
        require(msg.sender == item.buyer, "Only buyer can confirm receipt.");

        // 状態を先に変更（Reentrancy対策）
        item.status = Status.Completed;
        item.updatedAt = block.timestamp;

        // 売り手に代金を送金
        uint256 price = item.price;
        address payable seller = item.seller;

        (bool success, ) = seller.call{value: price}("");
        require(success, "Transfer to seller failed.");

        emit ReceiptConfirmed(
            _itemId,
            msg.sender,
            seller,
            price,
            block.timestamp
        );
    }

    /**
     * @notice 商品情報を更新する（出品者のみ）
     * @param _itemId 商品ID
     * @param _title 新しいタイトル
     * @param _price 新しい価格
     * @param _explanation 新しい説明
     * @param _imageUrl 新しい画像URL
     * @param _category 新しいカテゴリー
     */
    function updateItem(
        uint256 _itemId,
        string memory _title,
        uint256 _price,
        string memory _explanation,
        string memory _imageUrl,
        string memory _category
    ) public {
        Item storage item = items[_itemId];

        require(item.itemId != 0, "Item does not exist.");
        require(msg.sender == item.seller, "Only seller can update item.");
        require(item.status == Status.Listed, "Can only update listed items.");
        require(_price > 0, "Price must be greater than zero.");

        item.title = _title;
        item.price = _price;
        item.explanation = _explanation;
        item.imageUrl = _imageUrl;
        item.category = _category;
        item.updatedAt = block.timestamp;

        emit ItemUpdated(
            _itemId,
            _title,
            _price,
            _explanation,
            _imageUrl,
            _category,
            block.timestamp
        );
    }

    /**
     * @notice 商品情報を取得する
     * @param _itemId 商品ID
     */
    function getItem(uint256 _itemId) public view returns (Item memory) {
        require(items[_itemId].itemId != 0, "Item does not exist.");
        return items[_itemId];
    }

    /**
     * @notice 出品をキャンセルする（出品者のみ）
     * @param _itemId 商品ID
     */
    function cancelListing(uint256 _itemId) public {
        Item storage item = items[_itemId];

        require(item.itemId != 0, "Item does not exist.");
        require(msg.sender == item.seller, "Only seller can cancel listing.");
        require(item.status == Status.Listed, "Can only cancel listed items.");

        item.status = Status.Cancelled;
        item.updatedAt = block.timestamp;

        emit ItemCancelled(
            _itemId,
            msg.sender,
            block.timestamp
        );
    }
}
