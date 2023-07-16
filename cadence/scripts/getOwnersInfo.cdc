import BlogManager from 0xe03daebed8ca0615

pub fun main(owners:[Address]): { Address: {String: String} } {
    var ownersInfo: { Address: {String: String} }= {}
    for owner in owners{

        let account = getAccount(owner)
        let capa = account.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability from public collection")
        let ownerInfo = capa.getOwnerInfo()
        ownersInfo[owner] = ownerInfo
        
    }
    return ownersInfo
}
