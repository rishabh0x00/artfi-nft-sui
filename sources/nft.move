#[allow(lint(self_transfer))]
module nft::nft {

    // === Imports ===

    use sui::url::{Self, Url};
    use std::string;
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::vector;

    // ===== Error code ===== 

    const ELengthNotEqual: u64 = 11;


    // === Structs ===

    struct ArtFiNFT has key, store {
        id: UID,
        fractionId: u64,
        /// Name for the token
        artworkName: string::String,
        /// Description of the token
        description: string::String,
        /// URL for the token
        url: Url,
        /// royalty info
        royalty: Royalty
    }

    struct Royalty has store, drop, copy {
        artfi: u64,
        artist: u64,
        stakingContract: u64
    }

    struct AdminCap has key {
        id: UID
    }

    struct MinterCap has key {
        id: UID
    }

    // ===== Events =====

    struct NFTMinted has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        creator: address,
        // The name of the NFT
        name: string::String,
    }

    // ===== Public view functions =====

    /// Get the NFT's `name`
    public fun name(nft: &ArtFiNFT): &string::String {
        &nft.artworkName
    }

    /// Get the NFT's `description`
    public fun description(nft: &ArtFiNFT): &string::String {
        &nft.description
    }

    /// Get the NFT's `url`
    public fun url(nft: &ArtFiNFT): &Url {
        &nft.url
    }

    /// Get Royalty of NFT's
    public fun royalty(nft: &ArtFiNFT): &Royalty {
        &nft.royalty
    }

    /// Get artfi Royalty of NFT's
    public fun artfi_royalty(nft: &ArtFiNFT): &u64 {
        &nft.royalty.artfi
    }

    /// Get artist Royalty of NFT's
    public fun artist_royalty(nft: &ArtFiNFT): &u64 {
        &nft.royalty.artist
    }

    /// Get staking contract Royalty of NFT's
    public fun stakingContract_royalty(nft: &ArtFiNFT): &u64 {
        &nft.royalty.stakingContract
    }

    // ===== Entrypoints =====

    /// Module initializer is called only once on module publish.
    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        transfer::transfer(MinterCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    // === Public-Mutative Functions ===

    /// Transfer `nft` to `recipient`
    public fun transferNFT(
        nft: ArtFiNFT, recipient: address, _: &mut TxContext
    ) {
        transfer::public_transfer(nft, recipient)
    }

    /// Update the `description` of `nft` to `new_description`
    public fun update_description(
        nft: &mut ArtFiNFT,
        new_description: vector<u8>,
        _: &mut TxContext
    ) {
        nft.description = string::utf8(new_description)
    }

    /// Permanently delete `nft`
    public fun burn(nft: ArtFiNFT, _: &mut TxContext) {
        let ArtFiNFT { id, fractionId: _, artworkName: _, description: _, url: _, royalty: _ } = nft;
        object::delete(id)
    }

    // === Admin Functions ===

    /// Create a new nft
    public fun mintNFT(
        _: &MinterCap,
        artworkName: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        user: address,
        fractionId: u64,
        artfi: u64,
        artist: u64,
        stakingContract: u64,
        ctx: &mut TxContext
    ) { 
        mintFunc(
            artworkName, description, url, user, fractionId, Royalty{
               artfi, artist, stakingContract 
            } ,ctx
        );
    }
    
    /// Create a multiple nft
    public fun mintNftBatch(
        _: &MinterCap,
        name: &vector<vector<u8>>,
        description: &vector<vector<u8>>,
        url: &vector<vector<u8>>,
        user: address,
        fractionId: u64,
        artfi: &vector<u64>,
        artist: &vector<u64>,
        stakingContract: &vector<u64>,
        ctx: &mut TxContext
    ) {
        let lenghtOfVector = vector::length(name);
        assert!(lenghtOfVector == vector::length(description), ELengthNotEqual);
        assert!(lenghtOfVector == vector::length(url), ELengthNotEqual);

        let index = 0;
        while (index < lenghtOfVector) {

            mintFunc(
                *vector::borrow(name, index),
                *vector::borrow(description, index),
                *vector::borrow(url, index),
                user, 
                fractionId,
                Royalty{
                    artfi: *vector::borrow(artfi, index), 
                    artist: *vector::borrow(artist, index),
                    stakingContract: *vector::borrow(stakingContract, index)
                },
                ctx
            );

            index = index + 1;
        };
    }


    /// transfer AdminCap to newOwner
    public fun transferAdminCap(adminCap: AdminCap, newOwner: address) {
        transfer::transfer(adminCap, newOwner);
    }

    /// transfer new instance of MinterCap to minterOwner
    public fun transferMinterCap(_: &AdminCap, minterOwner: address, ctx: &mut TxContext) {
        transfer::transfer(MinterCap {
            id: object::new(ctx)
        }, minterOwner);
    }

    // === Private Functions ===
    
    fun mintFunc(
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        user: address,
        fractionId: u64,
        royalty: Royalty,
        ctx: &mut TxContext
    ) {
        let nft = ArtFiNFT {
            id: object::new(ctx),
            fractionId,
            artworkName: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url),
            royalty
        };

        event::emit(NFTMinted {
            object_id: object::id(&nft),
            creator: tx_context::sender(ctx),
            name: nft.artworkName,
        });

        transfer::public_transfer(nft, user);
    }  

    // === Test Functions ===

    #[test_only]
    public fun new_ArtFiNFT(
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        fractionId: u64,
        artfi: u64,
        artist: u64,
        stakingContract: u64,
        ctx: &mut TxContext
    ): ArtFiNFT {
        ArtFiNFT {
            id: object::new(ctx),
            fractionId,
            artworkName: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url),
            royalty: Royalty{
              artfi, artist, stakingContract  
            }
        }
    }
     
}