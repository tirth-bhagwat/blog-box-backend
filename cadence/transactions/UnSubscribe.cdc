
import FungibleToken from 0xee82856bf20e2aa6 
import FlowToken from 0x0ae53cb6e3f42a79
import BlogManager from 0xe03daebed8ca0615 // address of the blogger account
import Reader from 0x045a1763c93006ca // address of the subscriber's

transaction(bloggerAddr: Address) {

    // The Vault resource that holds the tokens that are being transferred
    let signerAddress: Address

    prepare(signer: AuthAccount) {
        self.signerAddress = signer.address

    }

    execute {
        BlogManager.unsubscribe(address: self.signerAddress)
        Reader.unsubscribe(address: bloggerAddr)
    }
}