
import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import BlogManager from 0xe03daebed8ca0615 // address of the blogger account
import Reader from 0x045a1763c93006ca // address of the subscriber's

transaction(amount: UFix64, bloggerAddr: Address) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault
    let signerAddress: Address

    prepare(signer: AuthAccount) {
        self.signerAddress = signer.address

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
        BlogManager.subscribe(address: self.signerAddress , vault: <- self.sentVault)
        Reader.subscribe(address: bloggerAddr)
    }
}