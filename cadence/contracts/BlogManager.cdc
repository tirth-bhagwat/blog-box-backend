import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
// import Reader from 0xe03daebed8ca0615

// import FungibleToken from 0x9a0766d93b6608b7
// import FlowToken from 0x7e60df042a9c0868


pub contract BlogManager {

    pub let BlogCollectionStoragePath : StoragePath
    pub let BlogCollectionPublicPath : PublicPath
    pub let FlowTokenVaultPath: PublicPath
    pub let SubscriptionsStoragePath: StoragePath
    pub let SubscriptionsPublicPath: PublicPath
    pub var idCount:UInt32
    access(contract) var subscriptionCost: UFix64

    pub enum BlogType: UInt8 {
        pub case PUBLIC
        pub case PRIVATE
    }

    pub resource Subscriptions {

        access(self) let subscribedTo: {Address: Bool};
        access(self) let subscriber: Address;

        init(_ subscriber: Address){
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

        pub fun isSubscribed(address: Address): Bool{
            return self.subscribedTo[address] ?? false;
        }

        pub fun getSubscriptions() : [Address]{
            return self.subscribedTo.keys;
        }

    }

    pub resource Blog {
        priv let id: UInt32
        priv let title: String
        priv let description: String
        priv let body: String
        priv let author: String
        priv let type: BlogType

        init(id:UInt32, title: String, description: String, body: String, author: String, type: BlogType) {
            self.id = id
            self.title = title
            self.description = description
            self.body = body
            self.author = author
            self.type = type
        }

        access(contract) fun isPublic(): Bool {
            return self.type == BlogType.PUBLIC
        }

        access(contract) fun getData(): {String:String} {
            return {
                "id": self.id.toString(),
                "title": self.title,
                "description": self.description,
                "body": self.body,
                "author": self.author,
                "type": self.type == BlogType.PUBLIC ? "PUBLIC" : "PRIVATE"
            }
        }
    }

    pub resource BlogCollection {
        priv let ownedBlogs: @{UInt32: Blog}
        priv var subscribers: {Address: Bool}
        priv let ownerAddr: Address

        init(_ owner: Address) {
            self.ownedBlogs <- {}
            self.subscribers = {}
            self.ownerAddr = owner
        }

        access(contract) fun add(blog:@Blog,id:UInt32){
            self.ownedBlogs[id]<-!blog;
        }

        access(contract) fun getBlog(id:UInt32):{String:String}{
            let blog <- self.ownedBlogs.remove(key: id)

            let data = blog?.getData()

            self.ownedBlogs[id]<-!blog;

            return data!

        }

        pub fun getKeys():[UInt32]{
            return self.ownedBlogs.keys;
        }

        pub fun getSubscribers():{Address: Bool}{
            return self.subscribers;
        }

        pub fun getOwner():Address{
            return self.ownerAddr;
        }

        access(contract) fun addSubscriber(address: Address){
            self.subscribers[address] = true
        }

        access(contract) fun removeSubscriber(address: Address){
            self.subscribers.remove(key: address)
        }

        destroy () {
            destroy self.ownedBlogs
        }

    }

    pub fun createEmptyCollection(): @BlogCollection{
        return <- create BlogCollection(self.account.address)
    }

    pub fun createEmptySubscriptions(_ subscriber: Address): @Subscriptions{
        return <- create Subscriptions(subscriber)
    }

    access(contract) fun addSubscriber(address: Address){
        // get the public capability
        let publicCapability = self.account.getCapability<&BlogCollection>(self.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability");

        // borrow the collection
        publicCapability.addSubscriber(address: address)
    }

    access(contract) fun removeSubscriber(address: Address){ 
        // get the public capability
        let publicCapability: &BlogManager.BlogCollection = self.account.getCapability<&BlogCollection>(self.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability");

        // borrow the collection
        publicCapability.removeSubscriber(address: address)
    }

    access(contract) fun verifySign( address: Address, message: String, signature: String, keyIndex: Int ): Bool 
    {

        let account = getAccount(address)
        let publicKeys = account.keys.get(keyIndex: 1) ?? panic("No key with that index in account")
        let publicKey = publicKeys.publicKey

        let sign = signature.decodeHex()
        let msg = message.utf8

        //     signature: signature,
        // signedData: message,
        // domainSeparationTag: "",
        // hashAlgorithm: HashAlgorithm.SHA2_256

        publicKey.verify(
            signature: sign,
            signedData: msg,
            domainSeparationTag: "",
            hashAlgorithm: HashAlgorithm.SHA2_256
        )

        return  true

    }

    pub fun createBlog(title: String, description: String, body: String, author: String, type: BlogType, blogCollection: &BlogCollection) {

        if blogCollection.getOwner() != self.account.address {
            panic("You are not the owner of this collection")
        }

        self.idCount = self.idCount + 1
        let newBlog: @BlogManager.Blog <- create Blog(id:self.idCount,title:title,description:description,body:body,author:author,type:type);

        let collection: &BlogManager.BlogCollection? = self.account.borrow<&BlogCollection>(from: self.BlogCollectionStoragePath);
        
        collection!.add(blog:<-newBlog,id:self.idCount);
    }

    pub fun getBlog(id:UInt32, address: Address, message: String, signature: String, keyIndex: Int): {String:String}? {

        if !self.isSubscribed(address: address) {
            return nil;
        }

        if !self.verifySign(address: address, message: message, signature: signature, keyIndex: keyIndex) {
            return nil;
        }

        let collection = self.account.borrow<&BlogCollection>(from: self.BlogCollectionStoragePath) ?? panic("Could not borrow capability");
        let blog = collection.getBlog(id:id);

        if blog == nil {
            panic("Blog not found")
        }


        return blog;

    }

    pub fun getAllBlogs(address: Address, message: String, signature: String, keyIndex: Int): [{String:String}]? {
        let collection = self.account.borrow<&BlogCollection>(from: self.BlogCollectionStoragePath) ?? panic("Could not borrow capability");

        if !self.isSubscribed(address: address) {
            return nil;
        }

        if !self.verifySign(address: address, message: message, signature: signature, keyIndex: keyIndex) {
            return nil;
        }

        let keys = collection.getKeys();

        var blogs: [{String:String}] = [];

        for key in keys {
            let blog = collection.getBlog(id:key);
            if (blog["type"] != "PUBLIC") {
                blog.remove(key: "body")
            }
            blogs.append(blog)
        }

        return blogs;
    }

    pub fun getBlogMetadata():[{String:String}]{
        let collection = self.account.borrow<&BlogCollection>(from: self.BlogCollectionStoragePath) ?? panic("Could not borrow capability");

        let keys = collection.getKeys();

        var blogs: [{String:String}] = [];

        for key in keys {
            let blog = collection.getBlog(id:key);
            if (blog["type"] != "PUBLIC") {
                blog.remove(key: "body")
            }
            blogs.append(blog)
        }

        return blogs;
    }

    pub fun subscribe(_ address: Address, vault: @FungibleToken.Vault, subscriptions: &Subscriptions) : Bool {
        if vault.balance != self.subscriptionCost {
            panic("Incorrect amount sent")
        }

        // if address is already subscribed
        if self.isSubscribed(address: address) {
            panic("Already subscribed")
        }

        let depositCapability = self.account.getCapability<&{FungibleToken.Receiver}>(self.FlowTokenVaultPath).borrow() ?? panic("Could not borrow capability")

        depositCapability.deposit(from: <- vault)

        self.addSubscriber(address: address)
        subscriptions.subscribe(blogger: address);

        return true
        
    }

    pub fun unsubscribe(readerAddr: Address, subscriptions: &Subscriptions) : Bool {
        if !self.isSubscribed(address: readerAddr) || subscriptions.getSubscriberId() != readerAddr {
            panic("Not subscribed")
        }

        self.removeSubscriber(address: readerAddr)

        return true
    }

    pub fun getSubscribers():{Address: Bool}{
        let collection = self.account.borrow<&BlogCollection>(from: self.BlogCollectionStoragePath);
        return collection!.getSubscribers();
    }

    pub fun isSubscribed(address: Address): Bool{
        let collection = self.account.borrow<&BlogCollection>(from: self.BlogCollectionStoragePath) ?? panic("Could not borrow capability");
        return collection.getSubscribers()[address] ?? false
    }

    init() {
        self.BlogCollectionStoragePath = /storage/BlogCollection
        self.BlogCollectionPublicPath = /public/BlogCollection

        self.SubscriptionsStoragePath = /storage/Subscriptions
        self.SubscriptionsPublicPath = /public/Subscriptions

        self.FlowTokenVaultPath = /public/flowTokenReceiver

        self.idCount = 0
        self.subscriptionCost = 22.0
 
        self.account.save(<-self.createEmptyCollection(), to: self.BlogCollectionStoragePath)
        self.account.link<&BlogCollection>(self.BlogCollectionPublicPath, target :self.BlogCollectionStoragePath)

        self.account.save(<-self.createEmptySubscriptions(self.account.address), to: self.SubscriptionsStoragePath)
        self.account.link<&Subscriptions>(self.SubscriptionsPublicPath, target :self.SubscriptionsStoragePath)

	}
}
