import FungibleToken from 0xee82856bf20e2aa6

pub contract Reader {

    pub var SubscriptionStoragePath: StoragePath
    pub var SubscriptionPublicPath: PublicPath


    pub resource Subscriptions{

        access(contract) let subscribedTo: {Address: Bool};

        init(){
            self.subscribedTo = {};
        }

        access(contract) fun subscribe(address: Address){
            self.subscribedTo[address] = true;
        }

        access(contract) fun unsubscribe(address: Address){
            self.subscribedTo.remove(key: address)
        }

        pub fun isSubscribed(address: Address): Bool{
            return self.subscribedTo[address] ?? false;
        }

        pub fun getSubscriptions() : [Address]{
            return self.subscribedTo.keys;
        }

    }


    init(){

        self.SubscriptionStoragePath = /storage/SubscrptionsCollection
        self.SubscriptionPublicPath = /public/SubscrptionsCollection

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

        let subscription = self.account.borrow<&Subscriptions>(from: self.SubscriptionStoragePath) ?? panic("Could not borrow capability from storage path");

        subscription.subscribe(address: address);

    }

    pub fun unsubscribe(address: Address){
        let subscription = self.account.borrow<&Subscriptions>(from: self.SubscriptionStoragePath) ?? panic("Could not borrow capability from storage path");

        subscription.unsubscribe(address: address);
    }

}