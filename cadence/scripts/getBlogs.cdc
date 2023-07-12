import BlogManager from 0xe03daebed8ca0615

pub fun main(address: Address, message: String, signature: String, keyIndex: Int): [{String: String}]? {

    let account = getAccount(0xe03daebed8ca0615)

    let capa = account.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability from public collection")

    return capa.getAllBlogs(address: address, message: message, signature: signature, keyIndex: keyIndex)
}
