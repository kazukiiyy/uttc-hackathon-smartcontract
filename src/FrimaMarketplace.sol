// src/FrimaMarketplace.sol
// ... (import FrimaNFT.sol) ...

contract FrimaMarketplace {
    FrimaNFT public nftContract;
    // ... (structs: Item, enum: Status) ...

    // ★★★ 通知の核 ★★★
    event ItemPurchased(
        uint256 indexed itemId,
        address indexed buyer,
        uint256 price,
        uint256 timestamp,
        uint256 tokenId
    );
    
    // ★★★ 購入/エスクローの核 ★★★
    function buyItem(uint256 _itemId) public payable {
        Item storage item = items[_itemId];
        // ... (各種チェック) ...

        // NFTの所有権移転 (権限がMarketplaceにあるため実行可能)
        nftContract.transferFrom(item.seller, msg.sender, item.tokenId);

        // 状態を「購入済み」に変更、代金はコントラクトに保持（エスクロー）
        item.status = Status.Purchased;
        item.buyer = msg.sender; 
        
        // 通知イベントの発行
        emit ItemPurchased(
            _itemId,
            msg.sender,
            msg.value, // msg.value はコントラクトに入金されたETHの量
            block.timestamp,
            item.tokenId
        );
    }
    
    // ... (confirmReceipt function for escrow release) ...
}

// src/FrimaMarketplace.sol
// ... (既存のコード) ...

contract FrimaMarketplace {
    FrimaNFT public nftContract;
    // ... (structs: Item, enum: Status) ...

    uint256 public itemIdCounter = 1; // 商品のユニークIDカウンター

    // ★★★ 出品時の通知イベント ★★★
    event ItemListed(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        string tokenURI
    );

    /**
     * @notice 新しい商品のNFTを発行し、マーケットプレイスに出品する
     * @param _price 価格 (Wei単位)
     * @param _tokenURI 商品メタデータ (IPFSハッシュなど)
     */
    function listItem(uint256 _price, string memory _tokenURI) public {
        require(_price > 0, "Price must be greater than zero.");

        // 1. NFTのミント (発行)
        // Seller (msg.sender) に新しいNFTを発行する
        // トークンIDには、ItemIdをそのまま使用する（シンプル化のため）
        uint256 newItemId = itemIdCounter;
        nftContract.safeMint(msg.sender, newItemId, _tokenURI);

        // 2. NFTのマーケットプレイスへの委任 (Approve)
        // NFTをマーケットプレイスが操作できるようにする。
        // ※ FrimaNFT.sol でapproveを制限しているので、ここでは外部からのapproveは不要（権限設定済みのため）
        // ただし、NFTコントラクトにApproveAllなどの機能があれば、ここで呼び出すか、
        // またはユーザーが事前に手動でMarketplaceに権限を与える必要があります。
        // 今回の FrimaNFT 設計では、マーケットプレイスは常に権限を持っています。

        // 3. 出品情報の登録
        items[newItemId] = Item({
            itemId: newItemId,
            tokenId: newItemId,
            seller: payable(msg.sender),
            buyer: payable(address(0)), // 初期値はゼロアドレス
            price: _price,
            status: Status.Listed
        });
        
        // 4. カウンターをインクリメント
        itemIdCounter++;

        // 5. DB連携用のイベント発行 (出品通知)
        emit ItemListed(
            newItemId,
            newItemId,
            msg.sender,
            _price,
            _tokenURI
        );
    }
}