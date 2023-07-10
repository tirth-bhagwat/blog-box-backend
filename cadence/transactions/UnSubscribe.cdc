
import FungibleToken from 0xee82856bf20e2aa6 
import FlowToken from 0x0ae53cb6e3f42a79
import BlogManager from 0xf669cb8d41ce0c74 // address of the blogger account

transaction() {

    let signerAddress: Address

    prepare(signer: AuthAccount) {
        self.signerAddress = signer.address
    }

    execute {
        let signer = getAccount(self.signerAddress)
        if signer.getCapability<&BlogManager.Subscriptions>(BlogManager.SubscriptionsPublicPath).borrow() == nil {
            panic("Signer has not subscribed to any blogger")
        }

        let subscriptions = signer.getCapability<&BlogManager.Subscriptions>(BlogManager.SubscriptionsPublicPath).borrow() ?? panic("Could not borrow subscriptions")

        BlogManager.unsubscribe(readerAddr: self.signerAddress, subscriptions: subscriptions)
    }
}