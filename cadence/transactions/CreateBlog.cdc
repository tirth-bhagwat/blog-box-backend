import BlogManager from 0xe03daebed8ca0615

transaction{
    prepare(signer: AuthAccount ){

        BlogManager.createBlog(id:1,title:"alice 1",description:"First Blog",body:"First Blog",author:"XYZ",type:"PUBLIC")
        
    }
}