import BlogManager from 0xe03daebed8ca0615


pub fun main(reader: Address): Bool {
    let account = getAccount(0xe03daebed8ca0615)
    let collection = account.getCapability(BlogManager.BlogCollectionPublicPath).borrow<&BlogManager.BlogCollection>() ?? panic("Could not borrow capability");

    return collection.isSubscribed(address: reader);

}