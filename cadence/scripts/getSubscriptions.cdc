import SubscriptionsManager from 0xf8d6e0586b0a20c7 // address of the global subscriber account

pub fun main(reader:Address): [Address] {

    let account = getAccount(reader)
    let capa = account.getCapability<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPub}>(SubscriptionsManager.SubscriptionsPublicPath).borrow() ?? panic("Could not borrow capability")

    let subs = capa.getSubscriptions()

    return subs

}

