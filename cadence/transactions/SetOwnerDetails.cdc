import BlogManager from 0xf669cb8d41ce0c74

transaction(name: String, avatar: String, bio: String, subscriptionCost: UFix64) {
    let signerAddr: Address
    prepare(signer: AuthAccount ){

        self.signerAddr = signer.address
        
    }
    execute{

        let signer = getAccount(self.signerAddr)
        if signer.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() == nil {
            panic("Signer is not a Blogger")
        }

        let blogCollectionRef = signer.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Signer is not a Blogger")

        BlogManager.updateDetails(name: name, avatar: avatar, bio: bio, subscriptionCost: subscriptionCost, blogCollection: blogCollectionRef)
        
    }
}