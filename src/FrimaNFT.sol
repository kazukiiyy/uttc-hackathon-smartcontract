// src/FrimaNFT.sol (修正案)
// ... (imports: ERC721, Ownable) ...

contract FrimaNFT is ERC721, Ownable {
    address public frimaMarketplace;

    // ... (constructor) ...

    // 新しいsafeMint関数 (tokenURIを受け取るように修正)
    function safeMint(address to, uint256 tokenId, string memory tokenURI) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }
    
    function setFrimaMarketplace(address _frimaMarketplace) public onlyOwner {
        frimaMarketplace = _frimaMarketplace;
    }
    
    // ★★★ 権限管理の核 1: 単体承認の制限 ★★★
    function approve(address to, uint256 tokenId) public virtual override {
        address ownerOfToken = ownerOf(tokenId);
        
        // NFTの所有者、またはマーケットプレイス以外からの承認を拒否する
        require(
            msg.sender == ownerOfToken || msg.sender == frimaMarketplace,
            "Approval is restricted to the Owner or Marketplace."
        );
        super.approve(to, tokenId);
    }

    // ★★★ 権限管理の核 2: 全承認の制限 (Operator) ★★★
    function setApprovalForAll(address operator, bool approved) public virtual override {
        // マーケットプレイスコントラクトは、誰に対しても全承認を拒否する
        // これにより、OpenSeaなどの外部サービスが全権限を得ることを防ぐ
        require(
            operator == frimaMarketplace,
            "Only the FrimaMarketplace can be set as an Operator."
        );
        super.setApprovalForAll(operator, approved);
    }

    // ★★★ 権限管理の核 3: 転送関数の制限 ★★★
    // マーケットプレイスの取引以外を禁止する。
    // 今回のケースでは、`transferFrom`を制限することが最も強力です。
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        // マーケットプレイスコントラクト、または所有者自身からの転送のみ許可
        require(
            msg.sender == from || msg.sender == frimaMarketplace,
            "Transfer restricted to Owner or Marketplace."
        );
        super.transferFrom(from, to, tokenId);
    }
}