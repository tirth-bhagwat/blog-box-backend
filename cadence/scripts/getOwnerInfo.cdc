import BlogManager from 0xe03daebed8ca0615

pub fun main(): {String: String}
{
    let account = getAccount(0xe03daebed8ca0615)

    let capa = account.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability from public collection")

    let ownerInfo = capa.getOwnerInfo()

    return ownerInfo

}
