import BlogManager from 0xf669cb8d41ce0c74

pub fun main(address: Address, message: String, signature: String, keyIndex: Int): [{String: String}]? {

    let account = getAccount(0xf669cb8d41ce0c74)

    let capa = account.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability from public collection")

    return capa.getAllBlogs(address: address, message: message, signature: signature, keyIndex: keyIndex)
    
}