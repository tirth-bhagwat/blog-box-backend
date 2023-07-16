pub contract SubscriptionsManager {

    pub let SubscriptionsStoragePath: StoragePath
    pub let SubscriptionsPublicPath: PublicPath
    pub let SubscriptionsPrivatePath: PrivatePath

    pub resource interface SubscriptionsPub {
        pub fun getSubscriberId(): Address;
        pub fun getSubscriptions(): [Address];
    }

    pub resource interface SubscriptionsPriv {
        pub fun getSubscriberId(): Address;
        pub fun getSubscriptions(): [Address];
        access(contract) fun subscribe(blogger: Address);
    }

    pub resource Subscriptions: SubscriptionsPub, SubscriptionsPriv {

        priv var subscribedTo: {Address: Bool};
        priv let subscriber: Address;

        init(_ subscriber: Address) {
            self.subscribedTo = {};
            self.subscriber = subscriber;
        }

        access(contract) fun subscribe(blogger: Address) {
            self.subscribedTo[blogger] = true;
        }

        access(contract) fun unsubscribe(address: Address){
            self.subscribedTo.remove(key: address)
        }

        pub fun getSubscriberId(): Address{
            return self.subscriber;
        }

        pub fun getSubscriptions() : [Address]{
            return self.subscribedTo.keys;
        }

    }

    pub fun createEmptySubscriptions(_ address: Address): @Subscriptions {
        return <- create Subscriptions(address);
    }

    pub fun subscribe(blogger: Address, reader: Address, subscriptions: &Subscriptions{SubscriptionsPriv}): Bool {
        if reader == subscriptions.getSubscriberId() {
            subscriptions.subscribe(blogger: blogger);
            return true;
        }

        return false;
    }

    init() {
        self.SubscriptionsStoragePath = /storage/Subscriptions
        self.SubscriptionsPublicPath = /public/Subscriptions
        self.SubscriptionsPrivatePath = /private/Subscriptions
    }

}