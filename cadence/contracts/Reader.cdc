import FungibleToken from 0xee82856bf20e2aa6
import BlogManager from 0xf669cb8d41ce0c74 // address of the blogger account

pub contract Reader {

    pub var SubscriptionStoragePath: StoragePath
    pub var SubscriptionPublicPath: PublicPath


    pub resource Subscriptions{

        access(contract) let subscribedTo: {Address: Bool};
        access(contract) let subscriber: Address;

        init(_ subscriber: Address){
            self.subscribedTo = {};
            self.subscriber = subscriber;
        }

        access(contract) fun subscribe(address: Address){
            self.subscribedTo[address] = true;
        }

        access(contract) fun unsubscribe(address: Address){
            self.subscribedTo.remove(key: address)
        }

        pub fun getSubscriberId(): Address{
            return self.subscriber;
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
        return <-create Subscriptions(self.account.address);
    }

    pub fun getSubscriptions(): &Subscriptions{
        return self.account.getCapability<&Subscriptions>(self.SubscriptionPublicPath).borrow() ?? panic("Could not borrow capability from public path")
    }

    pub fun subscribe(bloggerAddr: Address){
        // TODO check if address exists in subscriber list then add

        let blogger = getAccount(bloggerAddr);
        let capa = blogger.getCapability<&BlogManager>(BlogManager.BlogCollectionPublicPath)!.borrow() ?? panic("Could not borrow capability from public path");

        if capa.isSubscribed(address: bloggerAddr) {

            let subscription = self.account.borrow<&Subscriptions>(from: self.SubscriptionStoragePath) ?? panic("Could not borrow capability from storage path");

            subscription.subscribe(address: bloggerAddr);

        }


    }

    access(contract) fun unsubscribe(address: Address){
        let subscription = self.account.borrow<&Subscriptions>(from: self.SubscriptionStoragePath) ?? panic("Could not borrow capability from storage path");

        subscription.unsubscribe(address: address);
    }

}