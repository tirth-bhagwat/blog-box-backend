import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

pub contract BlogManager {

    pub let BlogCollectionStoragePath : StoragePath
    pub let BlogCollectionPublicPath : PublicPath
    pub let FlowTokenVaultPath: PublicPath
    pub let SubscriptionsStoragePath: StoragePath
    pub let SubscriptionsPublicPath: PublicPath

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
        priv let bannerImg: String
        priv let type: BlogType

        init(id:UInt32, title: String, description: String, body: String, author: String, bannerImg: String, type: BlogType) {
            self.id = id
            self.title = title
            self.description = description
            self.body = body
            self.author = author
            self.bannerImg = bannerImg
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
                "bannerImg": self.bannerImg,
                "type": self.type == BlogType.PUBLIC ? "PUBLIC" : "PRIVATE"
            }
        }
    }

    pub resource BlogCollection {
        priv let ownedBlogs: @{UInt32: Blog}
        priv var subscribers: {Address: Bool}
        priv var idCount: UInt32

        priv var subscriptionCost: UFix64?
        priv var ownerAddr: Address
        priv var ownerName: String?
        priv var ownerAvatar: String?
        priv var ownerBio: String?

        init(_ owner: Address, name: String?, avatar: String?, bio: String?, subscriptionCost: UFix64?) {
            self.ownedBlogs <- {}
            self.subscribers = {}
            self.idCount = 0

            self.ownerAddr = owner
            self.subscriptionCost = subscriptionCost
            self.ownerName = name
            self.ownerAvatar = avatar
            self.ownerBio = bio
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

        access(contract) fun addSubscriber(address: Address){
            self.subscribers[address] = true
        }

        access(contract) fun removeSubscriber(address: Address){
            self.subscribers.remove(key: address)
        }

        access(contract) fun updateSubscriptionCost(cost: UFix64){
            self.subscriptionCost = cost
        }

        access(contract) fun updateOwnerDetails(name: String, avatar: String, bio: String, subscriptionCost: UFix64){
            self.ownerName = name
            self.ownerAvatar = avatar
            self.ownerBio = bio
            self.subscriptionCost = subscriptionCost
        }

        access(contract) fun incrementId(){
            self.idCount = self.idCount + 1
        }

        pub fun verifySign( address: Address, message: String, signature: String, keyIndex: Int ): Bool 
        {

            let account = getAccount(address)
            let publicKeys = account.keys.get(keyIndex: keyIndex) ?? panic("No key with that index in account")
            let publicKey = publicKeys.publicKey

            let sign = signature.decodeHex()
            let msg = message.decodeHex()

            return publicKey.verify(
                signature: sign,
                signedData: msg,
                domainSeparationTag: "FLOW-V0.0-user",
                hashAlgorithm: HashAlgorithm.SHA3_256
            )

        }

        pub fun getIdCount(): UInt32{
            return self.idCount;
        }

        pub fun getKeys():[UInt32]{
            return self.ownedBlogs.keys;
        }

        pub fun getSubscribers():{Address: Bool}{
            return self.subscribers;
        }

        pub fun getSubscriptionCost(): UFix64{
            return self.subscriptionCost!;
        }

        pub fun isCostNil(): Bool{
            return self.subscriptionCost == nil;
        }

        pub fun getOwner():Address{
            return self.ownerAddr;
        }

        pub fun getOwnerInfo():{String:String}{
            return {
                "address": self.ownerAddr.toString(),
                "name": self.ownerName ?? "",
                "avatar": self.ownerAvatar ?? "",
                "bio": self.ownerBio ?? ""
            }
        }

        pub fun isSubscribed(address: Address): Bool{
            return self.getSubscribers()[address] ?? false
        }

        pub fun getBlogById(id:UInt32, address: Address, message: String, signature: String, keyIndex: Int): {String: String}? {

            if !self.isSubscribed(address: address) {
                return nil
            }

            if !self.verifySign(address: address, message: message, signature: signature, keyIndex: keyIndex) {
                return nil
            }

            if self.isCostNil() {
                panic("Subscription cost not set by owner")
            }

            let blog = self.getBlog(id:id);

            if blog == nil {
                panic("Blog not found")
            }

            return blog;

        }

        pub fun getAllBlogs(address: Address, message: String, signature: String, keyIndex: Int): [{String:String}]? {

            if !self.isSubscribed(address: address) {
                return nil;
            }

            if !self.verifySign(address: address, message: message, signature: signature, keyIndex: keyIndex) {
                return nil;
            }

            if self.isCostNil() {
                panic("Subscription cost not set by owner")
            }

            let keys = self.getKeys();

            var blogs: [{String:String}] = [];

            for key in keys {
                let blog = self.getBlog(id:key);
                blogs.append(blog)
            }

            return blogs;
        }

        destroy () {
            destroy self.ownedBlogs
        }

    }

    pub fun createEmptyCollection(): @BlogCollection{
        return <- create BlogCollection(self.account.address, name: nil, avatar: nil, bio: nil, subscriptionCost: nil)
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

    pub fun updateDetails(name: String, avatar: String, bio: String, subscriptionCost: UFix64, blogCollection: &BlogCollection) : Bool{
        if blogCollection.getOwner() != self.account.address {
            panic("You are not the owner of this collection")
        }

        blogCollection.updateSubscriptionCost(cost: subscriptionCost)

        blogCollection.updateOwnerDetails(name: name, avatar: avatar, bio: bio, subscriptionCost: subscriptionCost)

        return true
        
    }

    pub fun createBlog(title: String, description: String, body: String, author: String, bannerImg: String, type: BlogType, blogCollection: &BlogCollection) {

        if blogCollection.getOwner() != self.account.address {
            panic("You are not the owner of this collection")
        }

        if blogCollection.isCostNil() {
            panic("Please set a subscription cost for your blog collection")
        }

        blogCollection.incrementId()
        let newBlog: @BlogManager.Blog <- create Blog(id:blogCollection.getIdCount(),title:title,description:description,body:body,author:author, bannerImg: bannerImg, type: type)

        let collection: &BlogManager.BlogCollection? = self.account.borrow<&BlogCollection>(from: self.BlogCollectionStoragePath);
        
        collection!.add(blog:<-newBlog,id:blogCollection.getIdCount());
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
        let bloggerCapability = self.account.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability")

        if bloggerCapability.isCostNil() {
            panic("Subscription cost not set")
        }

        if vault.balance != bloggerCapability.getSubscriptionCost() {
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
        return collection.isSubscribed(address: address);
    }

    init() {
        self.BlogCollectionStoragePath = /storage/BlogCollection
        self.BlogCollectionPublicPath = /public/BlogCollection

        self.SubscriptionsStoragePath = /storage/Subscriptions
        self.SubscriptionsPublicPath = /public/Subscriptions

        self.FlowTokenVaultPath = /public/flowTokenReceiver

        self.account.save(<-self.createEmptyCollection(), to: self.BlogCollectionStoragePath)
        self.account.link<&BlogCollection>(self.BlogCollectionPublicPath, target :self.BlogCollectionStoragePath)

        self.account.save(<-self.createEmptySubscriptions(self.account.address), to: self.SubscriptionsStoragePath)
        self.account.link<&Subscriptions>(self.SubscriptionsPublicPath, target :self.SubscriptionsStoragePath)

	}
}
