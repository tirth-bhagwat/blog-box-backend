pub contract Reader {

    pub var SubscriptionStoragePath: StoragePath
    pub var SubscriptionPublicPath: PublicPath
    pub var MinterStoragePath: StoragePath


    pub resource Subscriptions{

        access(contract) let subscribedTo: {Address: Bool};

        init(){
            self.subscribedTo = {};
        }

        access(contract) fun subscribe(address: Address){
            self.subscribedTo[address] = true;
        }

        pub fun isSubscribed(address: Address): Bool{
            return self.subscribedTo[address] ?? false;
        }

        pub fun getSubscriptions() : [Address]{
            return self.subscribedTo.keys;
        }

    }


    init(){

        self.SubscriptionStoragePath = /storage/BlogCollection
        self.SubscriptionPublicPath = /public/BlogCollection
        self.MinterStoragePath = /storage/nftTutorialMinter

        self.account.save(<-self.createEmptySubscribtion(), to: self.SubscriptionStoragePath)
        self.account.link<&Subscriptions>(self.SubscriptionPublicPath, target :self.SubscriptionStoragePath)
        
    }

    pub fun createEmptySubscribtion() : @Subscriptions{
        return <-create Subscriptions()
    }

    pub fun getSubscriptions(): &Subscriptions{
        return self.account.getCapability<&Subscriptions>(self.SubscriptionPublicPath).borrow() ?? panic("Could not borrow capability from public path")
    }

    pub fun subscribe(address: Address){
        // TODO check if address exists in subscriber list then add
        let subscriptions = self.getSubscriptions()
        subscriptions.subscribe(address: address)
    }

}