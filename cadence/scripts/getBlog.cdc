import BlogManager from 0xe03daebed8ca0615

pub fun main(id: UInt32, address: Address, message: String, signature: String, keyIndex: Int): {String: String}? {

    let account = getAccount(0xe03daebed8ca0615)

    let capa = account.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability from public collection")

    return capa.getBlogById(id: id, address: address, message: message, signature: signature, keyIndex: keyIndex)
}
