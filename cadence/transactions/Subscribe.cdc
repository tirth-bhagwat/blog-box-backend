
import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import BlogManager from 0xe03daebed8ca0615 // address of the blogger account

transaction(amount: UFix64) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault
    let signerAddress: Address

    prepare(signer: AuthAccount) {
        self.signerAddress = signer.address

        if signer.borrow<&BlogManager.Subscriptions>(from: BlogManager.SubscriptionsStoragePath) == nil {
            signer.save(<- BlogManager.createEmptySubscriptions(self.signerAddress), to: BlogManager.SubscriptionsStoragePath)
            signer.link<&BlogManager.Subscriptions>(BlogManager.SubscriptionsPublicPath, target: BlogManager.SubscriptionsStoragePath)
        }

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)


    }

    execute {

        let signer = getAccount(self.signerAddress)
        let subs = signer.getCapability(BlogManager.SubscriptionsPublicPath).borrow<&BlogManager.Subscriptions>()
            ?? panic("Could not borrow capability from public storage")

        if BlogManager.subscribe(self.signerAddress, vault: <- self.sentVault, subscriptions: subs){
            log("Subscribed to blog")
        }
        else {
            log("Failed to subscribe to blog")
        }

    }

    post {
        
    }

}