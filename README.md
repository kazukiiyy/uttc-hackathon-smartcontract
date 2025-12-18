## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
# uttc-hackathon-smartcontract

## 概要

FrimaMarketplaceは、NFTベースのマーケットプレイスシステムです。商品をNFTとして発行し、ブロックチェーン上で安全に取引を行うことができます。

## コントラクト構成

### 1. FrimaNFT (`src/FrimaNFT.sol`)

ERC721準拠のNFTコントラクト。OpenZeppelinのERC721URIStorageとOwnableを継承しています。

#### 主な機能

- **NFTのミント**: マーケットプレイスまたはオーナーがNFTを発行
- **承認制限**: マーケットプレイス以外への承認を制限し、セキュリティを強化
- **転送制限**: マーケットプレイスまたは所有者のみが転送可能

#### 主要関数

- `safeMint(address to, uint256 tokenId, string memory uri)`: NFTをミントし、マーケットプレイスに自動承認
- `setFrimaMarketplace(address _frimaMarketplace)`: マーケットプレイスアドレスを設定（オーナーのみ）
- `approve(address to, uint256 tokenId)`: 承認（所有者またはマーケットプレイスのみ）
- `setApprovalForAll(address operator, bool approved)`: 全承認（マーケットプレイスのみ）
- `transferFrom(address from, address to, uint256 tokenId)`: 転送（所有者またはマーケットプレイスのみ）

### 2. FrimaMarketplace (`src/FrimaMarketplace.sol`)

商品の出品、購入、受け取り確認などの取引機能を提供するマーケットプレイスコントラクト。

#### 商品の状態（Status）

- `Listed`: 出品中
- `Purchased`: 購入済み（エスクロー中）
- `Completed`: 完了（受け取り確認済み）
- `Cancelled`: キャンセル済み

#### 主な機能

##### 1. 商品の出品 (`listItem`)

- 新しいNFTを発行し、マーケットプレイスに出品
- 商品情報（タイトル、価格、説明、画像URL、カテゴリーなど）を登録
- 出品時に`ItemListed`イベントを発行

**パラメータ:**
- `_title`: 商品タイトル
- `_price`: 価格（Wei単位）
- `_explanation`: 商品説明
- `_imageUrl`: 商品画像URL
- `_uid`: ユーザーID
- `_category`: カテゴリー
- `_tokenUri`: NFTメタデータURI（IPFSハッシュなど）

##### 2. 商品の購入 (`buyItem`)

- 出品中の商品を購入
- NFTの所有権を購入者に移転
- 支払い額が価格以上であることを確認
- 過払い分は自動返金
- 状態を`Purchased`に変更
- `ItemPurchased`イベントを発行

**制限:**
- 出品者は自分の商品を購入できない
- 出品中（`Listed`）の商品のみ購入可能

##### 3. 受け取り確認 (`confirmReceipt`)

- 購入者が商品の受け取りを確認
- エスクローされていた代金を売り手に送金
- 状態を`Completed`に変更
- `ReceiptConfirmed`イベントを発行

**制限:**
- 購入者のみが実行可能
- `Purchased`状態の商品のみ対象

##### 4. 商品情報の更新 (`updateItem`)

- 出品者が商品情報を更新
- タイトル、価格、説明、画像URL、カテゴリーを変更可能
- `ItemUpdated`イベントを発行

**制限:**
- 出品者のみが実行可能
- `Listed`状態の商品のみ更新可能

##### 5. 出品のキャンセル (`cancelListing`)

- 出品者が出品をキャンセル
- 状態を`Cancelled`に変更
- `ItemCancelled`イベントを発行

**制限:**
- 出品者のみが実行可能
- `Listed`状態の商品のみキャンセル可能

##### 6. 商品情報の取得 (`getItem`)

- 商品IDから商品情報を取得
- すべての商品データを返却

#### イベント

- `ItemListed`: 商品が出品されたとき
- `ItemPurchased`: 商品が購入されたとき
- `ItemUpdated`: 商品情報が更新されたとき
- `ItemCancelled`: 出品がキャンセルされたとき
- `ReceiptConfirmed`: 受け取り確認が行われたとき

## セキュリティ機能

1. **エスクロー機能**: 購入後、受け取り確認まで代金をエスクロー
2. **承認制限**: NFTの承認をマーケットプレイスに限定
3. **転送制限**: 不正な転送を防止
4. **過払い返金**: 購入時の過払い分を自動返金
5. **状態管理**: 適切な状態遷移のみ許可

## デプロイ手順

1. `FrimaNFT`コントラクトをデプロイ
2. `FrimaMarketplace`コントラクトをデプロイ（NFTコントラクトアドレスを指定）
3. `FrimaNFT`の`setFrimaMarketplace`関数でマーケットプレイスアドレスを設定

デプロイスクリプト (`script/FrimaMarketplace.s.sol`) を使用することで、上記の手順を自動化できます。

## テスト

Foundryを使用した包括的なテストスイートが含まれています。

```shell
forge test
```

テスト内容:
- 商品の出品
- 商品の購入
- 過払い時の返金
- 受け取り確認
- 出品のキャンセル
- 商品情報の更新
- 各種エラーケース（自分自身の商品購入、権限エラーなど）

## 技術スタック

- **Solidity**: ^0.8.20
- **Foundry**: 開発・テスト・デプロイフレームワーク
- **OpenZeppelin**: ERC721、Ownableなどの標準コントラクト
