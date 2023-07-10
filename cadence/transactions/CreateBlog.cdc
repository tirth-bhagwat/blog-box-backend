import BlogManager from 0xe03daebed8ca0615

transaction{
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

        BlogManager.createBlog(title:"First Blog",description:"First Blog",body:"First Blog",author:"XYZ",type:BlogManager.BlogType.PUBLIC, blogCollection: blogCollectionRef)

        BlogManager.createBlog(title:"Second Blog",description:"Second Blog",body:"Second Blog",author:"XYZ",type:BlogManager.BlogType.PUBLIC, blogCollection: blogCollectionRef)

        BlogManager.createBlog(title:"Third Blog",description:"Third Blog",body:"Third Blog",author:"XYZ",type:BlogManager.BlogType.PRIVATE, blogCollection: blogCollectionRef)

        BlogManager.createBlog(title:"Fourth Blog",description:"Fourth Blog",body:"Fourth Blog",author:"XYZ",type:BlogManager.BlogType.PRIVATE, blogCollection: blogCollectionRef)

    }
}