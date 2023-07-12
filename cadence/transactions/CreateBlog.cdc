import BlogManager from 0xe03daebed8ca0615

transaction(title: String, description: String, body: String, author: String, bannerImg: String, type: String) {
    let signerAddr: Address

    var blogType: BlogManager.BlogType
    
    prepare(signer: AuthAccount ){

        self.signerAddr = signer.address
        // if any input is empty, panic
        if title == "" || description == "" || body == "" || author == "" || bannerImg == "" || type == "" {
            panic("Missing input")
        }

        // if type is not public or private, panic
        if type.toLower() != "public" && type.toLower() != "private" {
            panic("Invalid blog type")
        }

        // if type is public, set blogType to public
        if type.toLower() == "public" {
            self.blogType = BlogManager.BlogType.PUBLIC
        }
        else{
            self.blogType = BlogManager.BlogType.PRIVATE
        }
        
    }

    execute{

        let signer = getAccount(self.signerAddr)
        if signer.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() == nil {
            panic("Signer is not a Blogger")
        }

        let blogCollectionRef = signer.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Signer is not a Blogger")

        BlogManager.createBlog(title:title,description:description,body:body,author:author,bannerImg:bannerImg,type:self.blogType, blogCollection: blogCollectionRef)

        BlogManager.createBlog(title:"First Blog",description:"First Blog",body:"First Blog",author:"XYZ",bannerImg:"",type:BlogManager.BlogType.PUBLIC, blogCollection: blogCollectionRef)

        BlogManager.createBlog(title:"Second Blog",description:"Second Blog",body:"Second Blog",author:"XYZ",bannerImg:"",type:BlogManager.BlogType.PUBLIC, blogCollection: blogCollectionRef)

        BlogManager.createBlog(title:"Third Blog",description:"Third Blog",body:"Third Blog",author:"XYZ",bannerImg:"",type:BlogManager.BlogType.PRIVATE, blogCollection: blogCollectionRef)

        BlogManager.createBlog(title:"Fourth Blog",description:"Fourth Blog",body:"Fourth Blog",author:"XYZ",bannerImg:"",type:BlogManager.BlogType.PRIVATE, blogCollection: blogCollectionRef)

    }
}