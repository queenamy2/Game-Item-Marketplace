;; Gaming NFT Marketplace & Asset Management System Smart Contract
;; A comprehensive blockchain-based gaming platform that enables creators and players
;; to mint, trade, craft, and manage gaming NFTs with integrated marketplace functionality,
;; advanced crafting mechanics, and complete asset lifecycle management for Web3 gaming ecosystems

;; SIP-009 NFT Standard Compliance
(impl-trait .nft-trait.nft-trait)

;; ERROR CONSTANTS & VALIDATION RULES

;; Authentication & Authorization Errors
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-CREATOR-PERMISSION-DENIED (err u101))
(define-constant ERR-OWNERSHIP-VALIDATION-FAILED (err u102))

;; Asset Management Errors
(define-constant ERR-GAMING-ASSET-NOT-FOUND (err u103))
(define-constant ERR-ASSET-ALREADY-EXISTS (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-ASSET-TRANSFER-RESTRICTED (err u106))

;; Transaction & Payment Errors
(define-constant ERR-TRANSACTION-FAILED (err u107))
(define-constant ERR-PAYMENT-ERROR (err u108))
(define-constant ERR-SELF-TRANSFER-PROHIBITED (err u109))

;; Marketplace Operation Errors
(define-constant ERR-LISTING-NOT-FOUND (err u110))
(define-constant ERR-LISTING-EXPIRED (err u111))
(define-constant ERR-LISTING-INACTIVE (err u112))
(define-constant ERR-INVALID-PRICE-CONFIGURATION (err u113))

;; Input Validation Errors
(define-constant ERR-INVALID-ADDRESS (err u114))
(define-constant ERR-INVALID-PARAMETER (err u115))
(define-constant ERR-EMPTY-STRING (err u116))
(define-constant ERR-INVALID-ATTRIBUTES (err u117))
(define-constant ERR-RECIPE-NOT-FOUND (err u118))

;; System Configuration Constants
(define-constant max-rarity-tier u10)
(define-constant min-rarity-tier u1)
(define-constant max-platform-fee-basis-points u1000) ;; 10.00%
(define-constant default-platform-fee-basis-points u250) ;; 2.50%
(define-constant invalid-address 'SP000000000000000000002Q6VF78)

;; GLOBAL STATE MANAGEMENT VARIABLES  

(define-data-var contract-owner principal tx-sender)
(define-data-var total-nft-count uint u0)
(define-data-var marketplace-fee-rate uint default-platform-fee-basis-points)
(define-data-var next-listing-id uint u1)
(define-data-var next-recipe-id uint u1)

;; DATA STRUCTURE DEFINITIONS

;; Gaming NFT Registry - Complete metadata storage
(define-map gaming-nft-registry
  uint ;; nft-token-id
  {
    display-name: (string-ascii 64),
    description: (string-utf8 256),
    image-uri: (string-utf8 256),
    creator-address: principal,
    asset-category: (string-ascii 32),
    trait-list: (list 20 {trait-name: (string-ascii 32), trait-value: (string-utf8 64)}),
    metadata-extension: (optional (string-utf8 1024)),
    creation-block-height: uint,
    rarity-tier: uint,
    is-tradeable: bool
  }
)

;; Asset Ownership Tracking
(define-map nft-ownership-records
  {token-id: uint, owner-address: principal}
  uint ;; quantity-owned
)

;; Marketplace Listings
(define-map marketplace-listings
  uint ;; listing-id
  {
    nft-token-id: uint,
    seller-address: principal,
    price-per-unit: uint,
    expiration-block: uint,
    quantity-available: uint,
    is-active: bool
  }
)

;; Creator Authorization Registry
(define-map authorized-creators principal bool)

;; Marketplace Indexing for Efficient Queries
(define-map active-listing-index uint bool)
(define-map seller-listing-index {seller: principal, listing: uint} bool)

;; Crafting Recipe System
(define-map crafting-recipes
  uint ;; recipe-id
  {
    base-asset-id: uint,
    material-requirements: (list 5 {material-id: uint, required-quantity: uint}),
    output-asset-id: uint,
    is-enabled: bool
  }
)

;; VALIDATION HELPER FUNCTIONS

(define-private (is-valid-address (address principal))
  (not (is-eq address invalid-address)))

(define-private (is-non-empty-ascii (text (string-ascii 64)))
  (> (len text) u0))

(define-private (is-non-empty-utf8 (text (string-utf8 256)))
  (> (len text) u0))

(define-private (is-non-empty-extended-utf8 (text (string-utf8 1024)))
  (> (len text) u0))

(define-private (is-valid-rarity-tier (rarity uint))
  (and (>= rarity min-rarity-tier) 
       (<= rarity max-rarity-tier)))

(define-private (is-valid-trait 
  (trait {trait-name: (string-ascii 32), trait-value: (string-utf8 64)}))
  (and
    (> (len (get trait-name trait)) u0)
    (> (len (get trait-value trait)) u0)))

(define-private (validate-trait-list 
  (traits (list 20 {trait-name: (string-ascii 32), trait-value: (string-utf8 64)})))
  (let ((trait-count (len traits)))
    (and
      (> trait-count u0)
      (fold check-individual-trait traits true))))

(define-private (check-individual-trait 
  (trait {trait-name: (string-ascii 32), trait-value: (string-utf8 64)}) 
  (is-valid bool))
  (and is-valid (is-valid-trait trait)))

(define-private (find-nft-owner (token-id uint))
  (let ((admin-balance (default-to u0 (map-get? nft-ownership-records 
                                                {token-id: token-id, 
                                                 owner-address: (var-get contract-owner)}))))
    (if (> admin-balance u0)
      (ok (some (var-get contract-owner)))
      (ok none))))

;; PLATFORM ADMINISTRATION

(define-read-only (get-contract-owner)
  (var-get contract-owner))

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-address new-owner) ERR-INVALID-ADDRESS)
    (ok (var-set contract-owner new-owner))))

(define-public (update-marketplace-fee (new-fee-rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (<= new-fee-rate max-platform-fee-basis-points) ERR-INVALID-PRICE-CONFIGURATION)
    (ok (var-set marketplace-fee-rate new-fee-rate))))

;; CREATOR AUTHORIZATION SYSTEM

(define-public (authorize-creator (creator-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-address creator-address) ERR-INVALID-ADDRESS)
    (ok (map-set authorized-creators creator-address true))))

(define-public (revoke-creator-authorization (creator-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-address creator-address) ERR-INVALID-ADDRESS)
    (ok (map-set authorized-creators creator-address false))))

(define-read-only (is-authorized-creator (creator-address principal))
  (default-to false (map-get? authorized-creators creator-address)))

;; SIP-009 STANDARD IMPLEMENTATION

(define-read-only (get-last-token-id)
  (ok (var-get total-nft-count)))

(define-read-only (get-token-uri (token-id uint))
  (let ((nft-data (map-get? gaming-nft-registry token-id)))
    (if (is-some nft-data)
      (ok (some (get image-uri (unwrap-panic nft-data))))
      (ok none))))

(define-read-only (get-owner (token-id uint))
  (let ((sender-balance (default-to u0 (map-get? nft-ownership-records 
                                                 {token-id: token-id, 
                                                  owner-address: tx-sender})))
        (admin-balance (default-to u0 (map-get? nft-ownership-records 
                                                {token-id: token-id, 
                                                 owner-address: (var-get contract-owner)}))))
    (if (> sender-balance u0)
      (ok (some tx-sender))
      (if (> admin-balance u0)
        (ok (some (var-get contract-owner)))
        (find-nft-owner token-id)))))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (transfer-gaming-nft token-id u1 sender recipient))


;; NFT CREATION & MINTING SYSTEM


(define-public (create-gaming-nft 
  (display-name (string-ascii 64))
  (description (string-utf8 256))
  (image-uri (string-utf8 256))
  (asset-category (string-ascii 32))
  (trait-list (list 20 {trait-name: (string-ascii 32), trait-value: (string-utf8 64)}))
  (metadata-extension (optional (string-utf8 1024)))
  (rarity-tier uint)
  (is-tradeable bool))
  (let ((new-token-id (+ (var-get total-nft-count) u1)))
    
    ;; Authorization Check
    (asserts! (or (is-eq tx-sender (var-get contract-owner))
                  (is-authorized-creator tx-sender)) ERR-CREATOR-PERMISSION-DENIED)
    
    ;; Input Validation
    (asserts! (is-non-empty-ascii display-name) ERR-EMPTY-STRING)
    (asserts! (is-non-empty-utf8 description) ERR-EMPTY-STRING)
    (asserts! (is-non-empty-utf8 image-uri) ERR-EMPTY-STRING)
    (asserts! (is-non-empty-ascii asset-category) ERR-EMPTY-STRING)
    (asserts! (is-valid-rarity-tier rarity-tier) ERR-INVALID-PARAMETER)
    (asserts! (validate-trait-list trait-list) ERR-INVALID-ATTRIBUTES)
    
    ;; Optional Metadata Validation
    (if (is-some metadata-extension)
      (asserts! (is-non-empty-extended-utf8 (unwrap! metadata-extension ERR-INVALID-PARAMETER)) ERR-EMPTY-STRING)
      true)
    
    ;; Store NFT Data
    (map-set gaming-nft-registry new-token-id {
      display-name: display-name,
      description: description,
      image-uri: image-uri,
      creator-address: tx-sender,
      asset-category: asset-category,
      trait-list: trait-list,
      metadata-extension: metadata-extension,
      creation-block-height: block-height,
      rarity-tier: rarity-tier,
      is-tradeable: is-tradeable
    })
    
    (var-set total-nft-count new-token-id)
    (ok new-token-id)))

(define-public (mint-gaming-nfts (token-id uint) (quantity uint) (recipient principal))
  (let ((nft-data (unwrap! (map-get? gaming-nft-registry token-id) ERR-GAMING-ASSET-NOT-FOUND))
        (current-balance (default-to u0 (map-get? nft-ownership-records 
                                                  {token-id: token-id, 
                                                   owner-address: recipient}))))
    
    ;; Authorization Check
    (asserts! (or (is-eq tx-sender (var-get contract-owner))
                  (is-eq tx-sender (get creator-address nft-data))) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Input Validation
    (asserts! (> quantity u0) ERR-INVALID-PARAMETER)
    (asserts! (is-valid-address recipient) ERR-INVALID-ADDRESS)
    
    ;; Update Ownership Records
    (map-set nft-ownership-records 
      {token-id: token-id, owner-address: recipient} 
      (+ current-balance quantity))
    
    (ok quantity)))

;; NFT TRANSFER SYSTEM

(define-public (transfer-gaming-nft 
  (token-id uint) 
  (transfer-quantity uint) 
  (sender-address principal) 
  (recipient-address principal))
  (let ((sender-balance (default-to u0 (map-get? nft-ownership-records 
                                                 {token-id: token-id, 
                                                  owner-address: sender-address})))
        (recipient-balance (default-to u0 (map-get? nft-ownership-records 
                                                    {token-id: token-id, 
                                                     owner-address: recipient-address})))
        (nft-data (unwrap! (map-get? gaming-nft-registry token-id) ERR-GAMING-ASSET-NOT-FOUND)))
    
    ;; Input Validation
    (asserts! (> transfer-quantity u0) ERR-INVALID-PARAMETER)
    (asserts! (is-valid-address recipient-address) ERR-INVALID-ADDRESS)
    
    ;; Authorization & Balance Checks
    (asserts! (or (is-eq tx-sender sender-address) 
                  (is-eq tx-sender (var-get contract-owner))) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (>= sender-balance transfer-quantity) ERR-INSUFFICIENT-BALANCE)
    (asserts! (get is-tradeable nft-data) ERR-ASSET-TRANSFER-RESTRICTED)
    (asserts! (not (is-eq sender-address recipient-address)) ERR-SELF-TRANSFER-PROHIBITED)
    
    ;; Execute Transfer
    (map-set nft-ownership-records 
      {token-id: token-id, owner-address: sender-address} 
      (- sender-balance transfer-quantity))
    
    (map-set nft-ownership-records 
      {token-id: token-id, owner-address: recipient-address} 
      (+ recipient-balance transfer-quantity))
    
    (ok true)))

(define-public (batch-transfer-nfts 
  (transfer-list (list 20 {token-id: uint, quantity: uint, recipient: principal})))
  (fold execute-single-transfer transfer-list (ok true)))

(define-private (execute-single-transfer 
  (transfer-data {token-id: uint, quantity: uint, recipient: principal}) 
  (previous-result (response bool uint)))
  (match previous-result
    success (transfer-gaming-nft 
              (get token-id transfer-data) 
              (get quantity transfer-data) 
              tx-sender 
              (get recipient transfer-data))
    failure previous-result))

;; NFT BURNING SYSTEM

(define-public (burn-gaming-nfts (token-id uint) (burn-quantity uint))
  (let ((owner-balance (get-nft-balance token-id tx-sender)))
    (asserts! (> burn-quantity u0) ERR-INVALID-PARAMETER)
    (asserts! (>= owner-balance burn-quantity) ERR-INSUFFICIENT-BALANCE)
    
    (map-set nft-ownership-records 
      {token-id: token-id, owner-address: tx-sender} 
      (- owner-balance burn-quantity))
    
    (ok true)))

;; MARKETPLACE TRADING SYSTEM

(define-public (create-marketplace-listing 
  (token-id uint) 
  (price-per-unit uint) 
  (quantity-available uint) 
  (expiration-block uint))
  (let ((new-listing-id (var-get next-listing-id))
        (seller-balance (get-nft-balance token-id tx-sender))
        (nft-data (unwrap! (map-get? gaming-nft-registry token-id) ERR-GAMING-ASSET-NOT-FOUND)))
    
    ;; Input Validation
    (asserts! (>= seller-balance quantity-available) ERR-INSUFFICIENT-BALANCE)
    (asserts! (> price-per-unit u0) ERR-INVALID-PRICE-CONFIGURATION)
    (asserts! (> quantity-available u0) ERR-INVALID-PARAMETER)
    (asserts! (> expiration-block block-height) ERR-LISTING-EXPIRED)
    (asserts! (get is-tradeable nft-data) ERR-ASSET-TRANSFER-RESTRICTED)
    
    ;; Create Listing
    (map-set marketplace-listings new-listing-id {
      nft-token-id: token-id,
      seller-address: tx-sender,
      price-per-unit: price-per-unit,
      expiration-block: expiration-block,
      quantity-available: quantity-available,
      is-active: true
    })
    
    ;; Update Indices
    (map-set active-listing-index new-listing-id true)
    (map-set seller-listing-index {seller: tx-sender, listing: new-listing-id} true)
    
    (var-set next-listing-id (+ new-listing-id u1))
    (ok new-listing-id)))

(define-public (cancel-marketplace-listing (listing-id uint))
  (let ((listing-data (unwrap! (map-get? marketplace-listings listing-id) ERR-LISTING-NOT-FOUND)))
    (asserts! (is-eq (get seller-address listing-data) tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (get is-active listing-data) ERR-LISTING-INACTIVE)
    
    ;; Deactivate Listing
    (map-set marketplace-listings listing-id 
      (merge listing-data {is-active: false}))
    
    (map-set active-listing-index listing-id false)
    (ok true)))

(define-public (purchase-from-marketplace 
  (listing-id uint) 
  (purchase-quantity uint))
  (let ((listing-data (unwrap! (map-get? marketplace-listings listing-id) ERR-LISTING-NOT-FOUND))
        (token-id (get nft-token-id listing-data))
        (unit-price (get price-per-unit listing-data))
        (seller-address (get seller-address listing-data))
        (available-quantity (get quantity-available listing-data))
        (total-cost (* unit-price purchase-quantity))
        (platform-fee (/ (* total-cost (var-get marketplace-fee-rate)) u10000))
        (seller-proceeds (- total-cost platform-fee)))
    
    ;; Input Validation
    (asserts! (> purchase-quantity u0) ERR-INVALID-PARAMETER)
    
    ;; Listing Validity Checks
    (asserts! (get is-active listing-data) ERR-LISTING-INACTIVE)
    (asserts! (<= block-height (get expiration-block listing-data)) ERR-LISTING-EXPIRED)
    (asserts! (<= purchase-quantity available-quantity) ERR-INSUFFICIENT-BALANCE)
    
    ;; Execute Payment
    (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? seller-proceeds tx-sender seller-address)))
    (try! (as-contract (stx-transfer? platform-fee tx-sender (var-get contract-owner))))
    
    ;; Transfer NFTs
    (try! (as-contract (transfer-gaming-nft token-id purchase-quantity seller-address tx-sender)))
    
    ;; Update or Close Listing
    (if (> available-quantity purchase-quantity)
      (map-set marketplace-listings listing-id 
        (merge listing-data {quantity-available: (- available-quantity purchase-quantity)}))
      (begin
        (map-set marketplace-listings listing-id 
          (merge listing-data {is-active: false, quantity-available: u0}))
        (map-set active-listing-index listing-id false)))
    
    (ok true)))

;; CRAFTING & UPGRADE SYSTEM

(define-public (create-crafting-recipe 
  (base-asset-id uint) 
  (material-requirements (list 5 {material-id: uint, required-quantity: uint}))
  (output-asset-id uint))
  (let ((new-recipe-id (var-get next-recipe-id)))
    
    ;; Authorization Check
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Input Validation
    (asserts! (is-some (map-get? gaming-nft-registry base-asset-id)) ERR-GAMING-ASSET-NOT-FOUND)
    (asserts! (is-some (map-get? gaming-nft-registry output-asset-id)) ERR-GAMING-ASSET-NOT-FOUND)
    (asserts! (> (len material-requirements) u0) ERR-INVALID-PARAMETER)
    
    ;; Create Recipe
    (map-set crafting-recipes new-recipe-id {
      base-asset-id: base-asset-id,
      material-requirements: material-requirements,
      output-asset-id: output-asset-id,
      is-enabled: true
    })
    
    (var-set next-recipe-id (+ new-recipe-id u1))
    (ok new-recipe-id)))

(define-public (execute-crafting (recipe-id uint))
  (let ((recipe-data (unwrap! (map-get? crafting-recipes recipe-id) ERR-RECIPE-NOT-FOUND))
        (base-asset (get base-asset-id recipe-data))
        (materials (get material-requirements recipe-data))
        (output-asset (get output-asset-id recipe-data)))
    
    (asserts! (get is-enabled recipe-data) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Verify Base Asset Ownership
    (asserts! (>= (get-nft-balance base-asset tx-sender) u1) ERR-INSUFFICIENT-BALANCE)
    
    ;; Verify Material Requirements
    (try! (fold verify-material-requirement materials (ok true)))
    
    ;; Consume Base Asset
    (try! (burn-gaming-nfts base-asset u1))
    
    ;; Consume Materials
    (try! (fold consume-material materials (ok true)))
    
    ;; Create Output Asset
    (try! (mint-gaming-nfts output-asset u1 tx-sender))
    
    (ok true)))

(define-private (verify-material-requirement 
  (material {material-id: uint, required-quantity: uint}) 
  (result (response bool uint)))
  (match result
    success (if (>= (get-nft-balance (get material-id material) tx-sender) 
                    (get required-quantity material))
             (ok true)
             ERR-INSUFFICIENT-BALANCE)
    error result))

(define-private (consume-material 
  (material {material-id: uint, required-quantity: uint}) 
  (result (response bool uint)))
  (match result
    success (burn-gaming-nfts (get material-id material) 
                             (get required-quantity material))
    error result))

(define-public (toggle-recipe-status 
  (recipe-id uint) 
  (enabled bool))
  (let ((recipe-data (unwrap! (map-get? crafting-recipes recipe-id) ERR-RECIPE-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> recipe-id u0) ERR-INVALID-PARAMETER)
    
    (map-set crafting-recipes recipe-id 
      (merge recipe-data {is-enabled: enabled}))
    
    (ok true)))

;; METADATA MANAGEMENT SYSTEM

(define-public (update-nft-metadata 
  (token-id uint) 
  (new-metadata (string-utf8 1024)))
  (let ((nft-data (unwrap! (map-get? gaming-nft-registry token-id) ERR-GAMING-ASSET-NOT-FOUND)))
    
    ;; Authorization Check
    (asserts! (or (is-eq tx-sender (var-get contract-owner))
                  (is-eq tx-sender (get creator-address nft-data))) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Input Validation
    (asserts! (is-non-empty-extended-utf8 new-metadata) ERR-EMPTY-STRING)
    
    ;; Update Metadata
    (map-set gaming-nft-registry token-id 
      (merge nft-data {metadata-extension: (some new-metadata)}))
    
    (ok true)))

(define-public (toggle-nft-tradeable-status 
  (token-id uint) 
  (tradeable-status bool))
  (let ((nft-data (unwrap! (map-get? gaming-nft-registry token-id) ERR-GAMING-ASSET-NOT-FOUND)))
    
    ;; Authorization Check
    (asserts! (or (is-eq tx-sender (var-get contract-owner))
                  (is-eq tx-sender (get creator-address nft-data))) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Update Status
    (map-set gaming-nft-registry token-id 
      (merge nft-data {is-tradeable: tradeable-status}))
    
    (ok true)))

;; READ-ONLY QUERY FUNCTIONS

(define-read-only (get-nft-details (token-id uint))
  (map-get? gaming-nft-registry token-id))

(define-read-only (get-nft-balance (token-id uint) (owner-address principal))
  (default-to u0 (map-get? nft-ownership-records {token-id: token-id, owner-address: owner-address})))

(define-read-only (get-listing-details (listing-id uint))
  (map-get? marketplace-listings listing-id))

(define-read-only (is-listing-active (listing-id uint))
  (let ((listing-data (map-get? marketplace-listings listing-id)))
    (match listing-data
      data (and (get is-active data) 
                (<= block-height (get expiration-block data)))
      false)))

(define-read-only (is-seller-listing (seller principal) (listing-id uint))
  (default-to false (map-get? seller-listing-index {seller: seller, listing: listing-id})))

(define-read-only (get-recipe-details (recipe-id uint))
  (map-get? crafting-recipes recipe-id))

(define-read-only (get-current-marketplace-fee)
  (var-get marketplace-fee-rate))

(define-read-only (get-total-nft-count)
  (var-get total-nft-count))

(define-read-only (get-next-listing-id)
  (var-get next-listing-id))

(define-read-only (get-next-recipe-id)
  (var-get next-recipe-id))

(define-read-only (is-nft-tradeable (token-id uint))
  (let ((nft-data (map-get? gaming-nft-registry token-id)))
    (match nft-data
      data (get is-tradeable data)
      false)))

(define-read-only (get-nft-creator (token-id uint))
  (let ((nft-data (map-get? gaming-nft-registry token-id)))
    (match nft-data
      data (some (get creator-address data))
      none)))

(define-read-only (get-nft-rarity (token-id uint))
  (let ((nft-data (map-get? gaming-nft-registry token-id)))
    (match nft-data
      data (some (get rarity-tier data))
      none)))

(define-read-only (get-nft-creation-block (token-id uint))
  (let ((nft-data (map-get? gaming-nft-registry token-id)))
    (match nft-data
      data (some (get creation-block-height data))
      none)))

(define-read-only (is-listing-expired (listing-id uint))
  (let ((listing-data (map-get? marketplace-listings listing-id)))
    (match listing-data
      data (> block-height (get expiration-block data))
      true)))

(define-read-only (calculate-marketplace-fee (total-price uint))
  (/ (* total-price (var-get marketplace-fee-rate)) u10000))

(define-read-only (get-user-portfolio (owner-address principal) (token-list (list 50 uint)))
  (map get-user-token-balance token-list))

(define-private (get-user-token-balance (token-id uint))
  {token-id: token-id, 
   balance: (get-nft-balance token-id tx-sender)})

;; PLATFORM ANALYTICS FUNCTIONS

(define-read-only (get-platform-stats)
  {
    total-nfts: (var-get total-nft-count),
    marketplace-fee: (var-get marketplace-fee-rate),
    contract-owner: (var-get contract-owner),
    next-listing-id: (var-get next-listing-id),
    next-recipe-id: (var-get next-recipe-id)
  })

(define-read-only (get-nft-trading-info (token-id uint))
  (let ((nft-data (map-get? gaming-nft-registry token-id)))
    (match nft-data
      data {
        exists: true,
        tradeable: (get is-tradeable data),
        rarity: (get rarity-tier data),
        category: (get asset-category data)
      }
      {
        exists: false,
        tradeable: false,
        rarity: u0,
        category: ""
      })))

;; EMERGENCY MANAGEMENT FUNCTIONS

(define-public (emergency-disable-nft-trading (token-id uint))
  (let ((nft-data (unwrap! (map-get? gaming-nft-registry token-id) ERR-GAMING-ASSET-NOT-FOUND)))
    ;; Authorization Check
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Validate Token ID
    (asserts! (> token-id u0) ERR-INVALID-PARAMETER)
    (asserts! (<= token-id (var-get total-nft-count)) ERR-GAMING-ASSET-NOT-FOUND)
    
    ;; Disable Trading
    (map-set gaming-nft-registry token-id 
      (merge nft-data {is-tradeable: false}))
    
    (ok true)))

(define-public (emergency-enable-nft-trading (token-id uint))
  (let ((nft-data (unwrap! (map-get? gaming-nft-registry token-id) ERR-GAMING-ASSET-NOT-FOUND)))
    ;; Authorization Check
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Validate Token ID
    (asserts! (> token-id u0) ERR-INVALID-PARAMETER)
    (asserts! (<= token-id (var-get total-nft-count)) ERR-GAMING-ASSET-NOT-FOUND)
    
    ;; Enable Trading
    (map-set gaming-nft-registry token-id 
      (merge nft-data {is-tradeable: true}))
    
    (ok true)))

(define-public (emergency-disable-all-recipes)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED-ACCESS)
    (ok true)))

;; CONTRACT INITIALIZATION

(begin
  (print "Gaming NFT Marketplace & Asset Management System (GNMAS) deployed successfully!")
  (print "Platform ready for NFT creation, trading, crafting, and comprehensive asset management.")
  (print "All systems operational - Welcome to the next generation of blockchain gaming!"))