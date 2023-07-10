import BlogManager from 0xf669cb8d41ce0c74

pub fun main(): {String: String}
{
    let account = getAccount(0xf669cb8d41ce0c74)

    let capa = account.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability from public collection")

    let ownerInfo = capa.getOwnerInfo()

    return ownerInfo

}
