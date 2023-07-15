import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import SubscriptionsManager from 0xf8d6e0586b0a20c7 // address of the global subscriber account

pub contract BlogManager {

    pub let BlogCollectionStoragePath : StoragePath
    pub let BlogCollectionPublicPath : PublicPath
    pub let FlowTokenVaultPath: PublicPath
    pub let SubscriptionsStoragePath: StoragePath
    pub let SubscriptionsPublicPath: PublicPath
    pub let SubscriptionsPrivatePath: PrivatePath

    pub enum BlogType: UInt8 {
        pub case PUBLIC
        pub case PRIVATE
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
        priv var subscribers: {Address: UFix64}
        priv var idCount: UInt32
        priv var subscriptionDuration: UFix64

        priv var subscriptionCost: UFix64?
        priv var ownerAddr: Address
        priv var ownerName: String?
        priv var ownerAvatar: String?
        priv var ownerBio: String?

        init(_ owner: Address, name: String?, avatar: String?, bio: String?, subscriptionCost: UFix64?) {
            self.ownedBlogs <- {}
            self.subscribers = {}
            self.idCount = 0

            // TODO: Make this a parameter later
            let subscriptionDays = 30
            self.subscriptionDuration = UFix64(subscriptionDays) * 24.0 * 60.0 * 60.0

            self.ownerAddr = owner
            self.subscriptionCost = subscriptionCost
            self.ownerName = name
            self.ownerAvatar = avatar
            self.ownerBio = bio

            self.addSubscriber(address: self.ownerAddr, timestamp: getCurrentBlock().timestamp)
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

        access(contract) fun addSubscriber(address: Address, timestamp: UFix64){
            self.subscribers[address] = timestamp
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

            // Check if given String is a valid hex string
            if message.length % 2 != 0 {
                panic("Invalid message hex string")
            }

            if signature.length % 2 != 0 {
                panic("Invalid signature hex string")
            }

            let sign = signature.decodeHex()
            let msg = message.decodeHex()

            let verificationRes = publicKey.verify(
                signature: sign,
                signedData: msg,
                // domainSeparationTag: "",
                domainSeparationTag: "FLOW-V0.0-user",
                hashAlgorithm: HashAlgorithm.SHA3_256
            )

            if !verificationRes {
                return false
            }

            let msgText = self.hexToText(hex: message)
            let msgTimestamp = UFix64.fromString(msgText)

            if msgTimestamp == nil {
                return false
            }

            let currentTimestamp = getCurrentBlock().timestamp;
            
            if msgTimestamp! > currentTimestamp {
                return false
            }

            if (currentTimestamp - msgTimestamp!) > 90.0 {
                return false
            }

            return true

        }

        pub fun hexToText(hex: String): String 
        {
            let length = hex.length

            let characterDictionary = {
                "00": "\u{0000}",
                "01": "\u{0001}",
                "02": "\u{0002}",
                "03": "\u{0003}",
                "04": "\u{0004}",
                "05": "\u{0005}",
                "06": "\u{0006}",
                "07": "\u{0007}",
                "08": "\u{0008}",
                "09": "\u{0009}",
                "0a": "\u{000A}",
                "0b": "\u{000B}",
                "0c": "\u{000C}",
                "0d": "\u{000D}",
                "0e": "\u{000E}",
                "0f": "\u{000F}",
                "10": "\u{0010}",
                "11": "\u{0011}",
                "12": "\u{0012}",
                "13": "\u{0013}",
                "14": "\u{0014}",
                "15": "\u{0015}",
                "16": "\u{0016}",
                "17": "\u{0017}",
                "18": "\u{0018}",
                "19": "\u{0019}",
                "1a": "\u{001A}",
                "1b": "\u{001B}",
                "1c": "\u{001C}",
                "1d": "\u{001D}",
                "1e": "\u{001E}",
                "1f": "\u{001F}",
                "20": " ",
                "21": "!",
                "22": "\"",
                "23": "#",
                "24": "$",
                "25": "%",
                "26": "&",
                "27": "'",
                "28": "(",
                "29": ")",
                "2a": "*",
                "2b": "+",
                "2c": ",",
                "2d": "-",
                "2e": ".",
                "2f": "/",
                "30": "0",
                "31": "1",
                "32": "2",
                "33": "3",
                "34": "4",
                "35": "5",
                "36": "6",
                "37": "7",
                "38": "8",
                "39": "9",
                "3a": ":",
                "3b": ";",
                "3c": "<",
                "3d": "=",
                "3e": ">",
                "3f": "?",
                "40": "@",
                "41": "A",
                "42": "B",
                "43": "C",
                "44": "D",
                "45": "E",
                "46": "F",
                "47": "G",
                "48": "H",
                "49": "I",
                "4a": "J",
                "4b": "K",
                "4c": "L",
                "4d": "M",
                "4e": "N",
                "4f": "O",
                "50": "P",
                "51": "Q",
                "52": "R",
                "53": "S",
                "54": "T",
                "55": "U",
                "56": "V",
                "57": "W",
                "58": "X",
                "59": "Y",
                "5a": "Z",
                "5b": "[",
                "5c": "\\",
                "5d": "]",
                "5e": "^",
                "5f": "_",
                "60": "`",
                "61": "a",
                "62": "b",
                "63": "c",
                "64": "d",
                "65": "e",
                "66": "f",
                "67": "g",
                "68": "h",
                "69": "i",
                "6a": "j",
                "6b": "k",
                "6c": "l",
                "6d": "m",
                "6e": "n",
                "6f": "o",
                "70": "p",
                "71": "q",
                "72": "r",
                "73": "s",
                "74": "t",
                "75": "u",
                "76": "v",
                "77": "w",
                "78": "x",
                "79": "y",
                "7a": "z",
                "7b": "{",
                "7c": "|",
                "7d": "}",
                "7e": "~",
                "7f": "\u{007F}"
            }

            var res = "";
            var i = 0

            while i < (length/2) {
                let startIndex = i * 2
                let endIndex = startIndex + 2
                let substring = hex.slice(from: startIndex, upTo: endIndex)
                let character = characterDictionary[substring] ?? panic("Invalid hex string or invalid character code: 0x".concat(substring))
                
                res = res.concat(character)
                i = i + 1
            }

            let resLen = res.length

            return res.slice(from: 32, upTo: resLen)
        }

        pub fun getIdCount(): UInt32{
            return self.idCount;
        }

        pub fun getKeys():[UInt32]{
            return self.ownedBlogs.keys;
        }

        pub fun getSubscribers():{Address: UFix64}{
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
                "bio": self.ownerBio ?? "",
                "subscriptionCost": self.subscriptionCost!.toString()
            }
        }

        pub fun getSubscriptionDuration(): UFix64{
            return self.subscriptionDuration;
        }

        pub fun isSubscribed(address: Address): Bool{
            let subscribedAt = self.subscribers[address] ?? 0.0;

            if subscribedAt == 0.0 { 
                return false;
            }

            if address == self.ownerAddr {
                return true;
            }

            let now = getCurrentBlock().timestamp;

            if now - subscribedAt > self.subscriptionDuration {
                return false;
            }

            return true;
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

    access(contract) fun addSubscriber(address: Address, timestamp: UFix64){
        // get the public capability
        let publicCapability = self.account.getCapability<&BlogCollection>(self.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability");

        // borrow the collection
        publicCapability.addSubscriber(address: address, timestamp: timestamp)
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

    pub fun subscribe(_ address: Address, vault: @FungibleToken.Vault, subscriptions: &SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}) : Bool {
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
        let timestamp: UFix64 = getCurrentBlock().timestamp;
        self.addSubscriber(address: address, timestamp: timestamp)
        SubscriptionsManager.subscribe(blogger: address, reader: address, subscriptions: subscriptions)

        return true
        
    }

    pub fun unsubscribe(readerAddr: Address, subscriptions: &SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}) : Bool {
        if !self.isSubscribed(address: readerAddr) || subscriptions.getSubscriberId() != readerAddr {
            panic("Not subscribed")
        }

        if self.account.address == subscriptions.getSubscriberId() {
            panic("Cannot unsubscribe from your own blog")
        }

        self.removeSubscriber(address: readerAddr)

        return true
    }

    pub fun getSubscribers():{Address: UFix64} {
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

        self.SubscriptionsStoragePath = SubscriptionsManager.SubscriptionsStoragePath;
        self.SubscriptionsPublicPath = SubscriptionsManager.SubscriptionsPublicPath;
        self.SubscriptionsPrivatePath = SubscriptionsManager.SubscriptionsPrivatePath;

        self.FlowTokenVaultPath = /public/flowTokenReceiver

        self.account.save(<-self.createEmptyCollection(), to: self.BlogCollectionStoragePath)
        self.account.link<&BlogCollection>(self.BlogCollectionPublicPath, target :self.BlogCollectionStoragePath)

        self.account.save(<-SubscriptionsManager.createEmptySubscriptions(self.account.address), to: self.SubscriptionsStoragePath)
        self.account.link<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPub}>(self.SubscriptionsPublicPath, target :self.SubscriptionsStoragePath)
        self.account.link<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}>(self.SubscriptionsPrivatePath, target :self.SubscriptionsStoragePath)

        let capa = self.account.getCapability<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}>(self.SubscriptionsPrivatePath).borrow() ?? panic("Could not borrow capability Subscriptions from Blogger's public path")

        SubscriptionsManager.subscribe(blogger: self.account.address, reader:self.account.address, subscriptions: capa)

	}
}
