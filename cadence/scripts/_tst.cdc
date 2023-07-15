import SubscriptionsManager from 0xf8d6e0586b0a20c7 // address of the global subscriber account
// import BlogManager from 0xe03daebed8ca0615

pub fun main(): Bool {
    let account = getAccount(0xf8d6e0586b0a20c7)
    // let capa: DeployedContract = account.contracts.get(name:"BlogManager") ?? panic("Could not find contract")
    // account.contracts.get(name:"MyContract")!.publicTypes()
    // let typ = capa.publicTypes()[0].getType()
    // let cap = account.getCapability(/public/BlogCollection);
    let capa = account.getCapability<&SubscriptionsManager.Subscriptions>(SubscriptionsManager.SubscriptionsPublicPath).borrow() ?? panic("Could not borrow capability Subscriptions from Blogger's public path")


    return true

}