
import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import BlogManager from 0xe03daebed8ca0615 // address of the blogger account
import SubscriptionsManager from 0xf8d6e0586b0a20c7 // address of the global subscriber account

transaction(amount: UFix64) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault
    let signerAddress: Address
    let subscriptionsPrivate: &SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}

    prepare(signer: AuthAccount) {
        self.signerAddress = signer.address

        if signer.borrow<&SubscriptionsManager.Subscriptions>(from: SubscriptionsManager.SubscriptionsStoragePath) == nil {
            // Create a new empty subscriptions collection
            signer.save(<- SubscriptionsManager.createEmptySubscriptions(self.signerAddress), to: SubscriptionsManager.SubscriptionsStoragePath)
            // Create public capability for the subscriptions collection
            signer.link<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPub}>(SubscriptionsManager.SubscriptionsPublicPath, target: SubscriptionsManager.SubscriptionsStoragePath)
            // Create private capability for the subscriptions collection
            signer.link<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}>(SubscriptionsManager.SubscriptionsPrivatePath, target: SubscriptionsManager.SubscriptionsStoragePath)
        }

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)

        self.subscriptionsPrivate 
            = signer.getCapability(SubscriptionsManager.SubscriptionsPrivatePath)
                .borrow<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}>()
                ?? panic("Could not borrow capability from public storage")

    }

    execute {
        if BlogManager.subscribe(self.signerAddress, vault: <- self.sentVault, subscriptions: self.subscriptionsPrivate){
            log("Subscribed to blog")
        }
        else {
            log("Failed to subscribe to blog")
        }
    }

}