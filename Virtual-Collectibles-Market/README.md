# Gaming NFT Marketplace & Asset Management System

A comprehensive blockchain-based gaming platform that enables creators and players to mint, trade, craft, and manage gaming NFTs with integrated marketplace functionality, advanced crafting mechanics, and complete asset lifecycle management for Web3 gaming ecosystems.

## Overview

GNMAS is a feature-rich smart contract built on the Stacks blockchain that provides:
- **NFT Creation & Minting**: Create gaming assets with rich metadata and traits
- **Marketplace Trading**: Built-in marketplace with listings, purchases, and fee management
- **Crafting System**: Recipe-based asset crafting and upgrades
- **Asset Management**: Complete lifecycle management of gaming NFTs
- **Creator Authorization**: Permission-based creation system
- **Portfolio Management**: User asset tracking and analytics

## Features

### Core NFT Functionality
- **SIP-009 Standard Compliance**: Full compatibility with Stacks NFT standard
- **Rich Metadata Support**: Display names, descriptions, images, traits, and extended metadata
- **Rarity System**: 10-tier rarity classification (1-10)
- **Asset Categories**: Flexible categorization system
- **Tradeable Status**: Toggle trading permissions per asset

### Marketplace System
- **Active Listings**: Time-bound marketplace listings with quantity management
- **Automated Payments**: Built-in STX payment processing with platform fees
- **Fee Management**: Configurable platform fees (default 2.5%, max 10%)
- **Listing Management**: Create, cancel, and manage marketplace listings
- **Batch Operations**: Efficient bulk transfer capabilities

### Crafting & Upgrades
- **Recipe System**: Define crafting recipes with material requirements
- **Asset Consumption**: Burn base assets and materials for crafting
- **Output Generation**: Create new assets through crafting
- **Recipe Management**: Enable/disable recipes dynamically

### Administration
- **Owner Management**: Transferable contract ownership
- **Creator Authorization**: Whitelist system for authorized creators
- **Fee Configuration**: Adjustable marketplace fees
- **Emergency Controls**: Disable trading or recipes when needed

## Prerequisites

- Stacks wallet (Hiro Wallet, Xverse, etc.)
- STX tokens for transactions and marketplace purchases
- Clarity smart contract deployment environment

## Installation

1. **Deploy the Contract**:
   ```bash
   clarinet deploy --network=testnet
   ```

2. **Verify Deployment**:
   ```clarity
   (contract-call? .gnmas get-platform-stats)
   ```

## Usage Guide

### For Contract Owners

#### Initialize Creator Authorization
```clarity
;; Authorize a creator
(contract-call? .gnmas authorize-creator 'SP1234567890ABCDEF)

;; Set marketplace fee (250 = 2.5%)
(contract-call? .gnmas update-marketplace-fee u250)
```

### For Creators

#### Create a Gaming NFT
```clarity
(contract-call? .gnmas create-gaming-nft 
  "Epic Sword"                           ;; display-name
  u"A legendary blade forged in fire"    ;; description
  u"https://example.com/sword.png"       ;; image-uri
  "weapon"                               ;; asset-category
  (list 
    {trait-name: "Attack", trait-value: u"150"}
    {trait-name: "Rarity", trait-value: u"Legendary"})
  (some u"Extended lore and backstory")  ;; metadata-extension
  u8                                     ;; rarity-tier (1-10)
  true)                                  ;; is-tradeable
```

#### Mint NFTs to Users
```clarity
(contract-call? .gnmas mint-gaming-nfts 
  u1                                     ;; token-id
  u5                                     ;; quantity
  'SP1234567890ABCDEF)                   ;; recipient
```

### For Players

#### Transfer NFTs
```clarity
(contract-call? .gnmas transfer-gaming-nft 
  u1                                     ;; token-id
  u1                                     ;; quantity
  tx-sender                              ;; sender
  'SP0987654321FEDCBA)                   ;; recipient
```

#### Create Marketplace Listing
```clarity
(contract-call? .gnmas create-marketplace-listing 
  u1                                     ;; token-id
  u1000000                               ;; price-per-unit (1 STX)
  u3                                     ;; quantity-available
  u1500)                                 ;; expiration-block
```

#### Purchase from Marketplace
```clarity
(contract-call? .gnmas purchase-from-marketplace 
  u1                                     ;; listing-id
  u2)                                    ;; purchase-quantity
```

#### Execute Crafting
```clarity
(contract-call? .gnmas execute-crafting u1) ;; recipe-id
```

## Query Functions

### Get NFT Information
```clarity
;; Get complete NFT details
(contract-call? .gnmas get-nft-details u1)

;; Check user's balance
(contract-call? .gnmas get-nft-balance u1 'SP1234567890ABCDEF)

;; Get NFT trading status
(contract-call? .gnmas is-nft-tradeable u1)
```

### Marketplace Queries
```clarity
;; Get listing details
(contract-call? .gnmas get-listing-details u1)

;; Check if listing is active
(contract-call? .gnmas is-listing-active u1)

;; Calculate marketplace fee
(contract-call? .gnmas calculate-marketplace-fee u1000000)
```

### Platform Analytics
```clarity
;; Get platform statistics
(contract-call? .gnmas get-platform-stats)

;; Get user portfolio
(contract-call? .gnmas get-user-portfolio 
  'SP1234567890ABCDEF 
  (list u1 u2 u3 u4 u5))
```

## Contract Architecture

### Data Structures

**Gaming NFT Registry**
- Complete NFT metadata storage
- Creator information and timestamps
- Rarity and trading permissions

**Ownership Records**
- Token-owner mapping with quantities
- Efficient balance tracking

**Marketplace Listings**
- Active listing management
- Price and expiration tracking
- Quantity and seller information

**Crafting Recipes**
- Material requirements definition
- Input-output asset mapping
- Recipe status management

### Key Constants

```clarity
;; Rarity System
max-rarity-tier: u10
min-rarity-tier: u1

;; Fee Structure
max-platform-fee-basis-points: u1000  ;; 10.00%
default-platform-fee-basis-points: u250  ;; 2.50%
```

## Security Features

- **Authorization Checks**: Multi-level permission system
- **Input Validation**: Comprehensive parameter validation
- **Balance Verification**: Prevents overdraft and invalid transfers
- **Self-Transfer Protection**: Blocks transfers to same address
- **Expiration Management**: Time-bound listing system
- **Emergency Controls**: Owner-only emergency functions

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR-UNAUTHORIZED-ACCESS | Insufficient permissions |
| u101 | ERR-CREATOR-PERMISSION-DENIED | Creator authorization required |
| u102 | ERR-OWNERSHIP-VALIDATION-FAILED | Ownership verification failed |
| u103 | ERR-GAMING-ASSET-NOT-FOUND | NFT does not exist |
| u104 | ERR-ASSET-ALREADY-EXISTS | Duplicate asset creation |
| u105 | ERR-INSUFFICIENT-BALANCE | Insufficient token balance |
| u106 | ERR-ASSET-TRANSFER-RESTRICTED | Trading disabled for asset |
| u107 | ERR-TRANSACTION-FAILED | Transaction execution failed |
| u108 | ERR-PAYMENT-ERROR | Payment processing error |
| u109 | ERR-SELF-TRANSFER-PROHIBITED | Cannot transfer to self |
| u110 | ERR-LISTING-NOT-FOUND | Marketplace listing not found |
| u111 | ERR-LISTING-EXPIRED | Listing has expired |
| u112 | ERR-LISTING-INACTIVE | Listing is not active |
| u113 | ERR-INVALID-PRICE-CONFIGURATION | Invalid price settings |
| u114 | ERR-INVALID-ADDRESS | Invalid principal address |
| u115 | ERR-INVALID-PARAMETER | Invalid function parameter |
| u116 | ERR-EMPTY-STRING | Empty string not allowed |
| u117 | ERR-INVALID-ATTRIBUTES | Invalid trait attributes |
| u118 | ERR-RECIPE-NOT-FOUND | Crafting recipe not found |

## Advanced Features

### Batch Operations
- Bulk NFT transfers
- Portfolio queries
- Multi-asset management

### Analytics Integration
- Platform statistics
- User portfolio tracking
- Trading information queries

### Emergency Management
- Disable/enable trading per NFT
- Recipe system controls
- Owner-only emergency functions