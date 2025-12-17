// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FrimaNFT is ERC721, ERC721URIStorage, Ownable {
    address public frimaMarketplace;

    constructor() ERC721("FrimaNFT", "FRIMA") Ownable(msg.sender) {}

    function safeMint(address to, uint256 tokenId, string memory uri) public {
        require(
            msg.sender == owner() || msg.sender == frimaMarketplace,
            "Only owner or marketplace can mint."
        );
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        // ミント時にマーケットプレイスに承認を与える
        _approve(frimaMarketplace, tokenId, to);
    }

    function setFrimaMarketplace(address _frimaMarketplace) public onlyOwner {
        frimaMarketplace = _frimaMarketplace;
    }

    // 単体承認の制限
    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        address ownerOfToken = ownerOf(tokenId);
        require(
            msg.sender == ownerOfToken || msg.sender == frimaMarketplace,
            "Approval is restricted to the Owner or Marketplace."
        );
        super.approve(to, tokenId);
    }

    // 全承認の制限
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) {
        require(
            operator == frimaMarketplace,
            "Only the FrimaMarketplace can be set as an Operator."
        );
        super.setApprovalForAll(operator, approved);
    }

    // 転送関数の制限
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        require(
            msg.sender == from || msg.sender == frimaMarketplace,
            "Transfer restricted to Owner or Marketplace."
        );
        super.transferFrom(from, to, tokenId);
    }

    // Required overrides
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
