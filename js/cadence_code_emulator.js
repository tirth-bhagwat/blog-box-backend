export const SubscriptionsManager = `
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

        priv let subscribedTo: {Address: Bool};
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
`;
export const BlogManager = `
import FungibleToken from 0xFungibleToken
import FlowToken from 0xFlowToken
import SubscriptionsManager from 0xDeployer // address of the global subscriber account

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
                "60": "\`",
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

        let collectionConditions = [
            self.account.storagePaths.contains(self.BlogCollectionStoragePath),
            self.account.getCapability<&BlogCollection>(self.BlogCollectionPublicPath).check()
        ]

        if collectionConditions.contains(true) {
            panic("Invalid BlogCollection contract")
        }
        self.account.save(<-self.createEmptyCollection(), to: self.BlogCollectionStoragePath)
        self.account.link<&BlogCollection>(self.BlogCollectionPublicPath, target :self.BlogCollectionStoragePath)

        let subscriptionsConditions = [
            self.account.storagePaths.contains(SubscriptionsManager.SubscriptionsStoragePath),
            self.account.getCapability<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPub}>(SubscriptionsManager.SubscriptionsPublicPath).check(),
            self.account.getCapability<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}>(SubscriptionsManager.SubscriptionsPrivatePath).check()
        ]

        if subscriptionsConditions.contains(true) {

            if subscriptionsConditions[0] && subscriptionsConditions[1] && subscriptionsConditions[2] {
                
                let capa = self.account.getCapability<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}>(self.SubscriptionsPrivatePath).borrow() ?? panic("Could not borrow capability Subscriptions from Blogger's public path")
                SubscriptionsManager.subscribe(blogger: self.account.address, reader:self.account.address, subscriptions: capa)
            }
            else {
                panic("Invalid SubscriptionsManager contract")
            }

        }
        else {
            self.account.save(<-SubscriptionsManager.createEmptySubscriptions(self.account.address), to: self.SubscriptionsStoragePath)
            self.account.link<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPub}>(self.SubscriptionsPublicPath, target :self.SubscriptionsStoragePath)
            self.account.link<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}>(self.SubscriptionsPrivatePath, target :self.SubscriptionsStoragePath)
            let capa = self.account.getCapability<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}>(self.SubscriptionsPrivatePath).borrow() ?? panic("Could not borrow capability Subscriptions from Blogger's public path")

            SubscriptionsManager.subscribe(blogger: self.account.address, reader:self.account.address, subscriptions: capa)
        }

	}
}

`;
export const CreateBlog = `
import BlogManager from 0xBlogger

transaction(title: String, description: String, body: String, author: String, bannerImg: String, type: String) {
    let signerAddr: Address

    var blogType: BlogManager.BlogType
    
    prepare(signer: AuthAccount ){

        self.signerAddr = signer.address
        // if any input is empty, panic
        if title == "" || description == "" || body == "" || author == "" || bannerImg == "" || type == "" {
            panic("Missing input")
        }

        // if type is not public or private, panic
        if type.toLower() != "public" && type.toLower() != "private" {
            panic("Invalid blog type")
        }

        // if type is public, set blogType to public
        if type.toLower() == "public" {
            self.blogType = BlogManager.BlogType.PUBLIC
        }
        else{
            self.blogType = BlogManager.BlogType.PRIVATE
        }
        
    }

    execute{

        let signer = getAccount(self.signerAddr)
        if signer.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() == nil {
            panic("Signer is not a Blogger")
        }

        let blogCollectionRef = signer.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Signer is not a Blogger")

        BlogManager.createBlog(title:title,description:description,body:body,author:author,bannerImg:bannerImg,type:self.blogType, blogCollection: blogCollectionRef)

        BlogManager.createBlog(title:"First Blog",description:"First Blog",body:"First Blog",author:"XYZ",bannerImg:"",type:BlogManager.BlogType.PUBLIC, blogCollection: blogCollectionRef)

        BlogManager.createBlog(title:"Second Blog",description:"Second Blog",body:"Second Blog",author:"XYZ",bannerImg:"",type:BlogManager.BlogType.PUBLIC, blogCollection: blogCollectionRef)

        BlogManager.createBlog(title:"Third Blog",description:"Third Blog",body:"Third Blog",author:"XYZ",bannerImg:"",type:BlogManager.BlogType.PRIVATE, blogCollection: blogCollectionRef)

        BlogManager.createBlog(title:"Fourth Blog",description:"Fourth Blog",body:"Fourth Blog",author:"XYZ",bannerImg:"",type:BlogManager.BlogType.PRIVATE, blogCollection: blogCollectionRef)

    }
}
`;
export const DeployContract = `
import FungibleToken from 0xFungibleToken
import FlowToken from 0xFlowToken

transaction {
    prepare(acct: AuthAccount) {
        let signer = acct
        // get the list of existing contracts
        var existingContracts = signer.contracts.names
        let BlogManager = "696d706f72742046756e6769626c65546f6b656e2066726f6d203078656538323835366266323065326161360a696d706f727420466c6f77546f6b656e2066726f6d203078306165353363623665336634326137390a696d706f727420537562736372697074696f6e734d616e616765722066726f6d20307866386436653035383662306132306337202f2f2061646472657373206f662074686520676c6f62616c2073756273637269626572206163636f756e740a0a70756220636f6e747261637420426c6f674d616e61676572207b0a0a20202020707562206c657420426c6f67436f6c6c656374696f6e53746f7261676550617468203a2053746f72616765506174680a20202020707562206c657420426c6f67436f6c6c656374696f6e5075626c696350617468203a205075626c6963506174680a20202020707562206c657420466c6f77546f6b656e5661756c74506174683a205075626c6963506174680a20202020707562206c657420537562736372697074696f6e7353746f72616765506174683a2053746f72616765506174680a20202020707562206c657420537562736372697074696f6e735075626c6963506174683a205075626c6963506174680a20202020707562206c657420537562736372697074696f6e7350726976617465506174683a2050726976617465506174680a0a2020202070756220656e756d20426c6f67547970653a2055496e7438207b0a20202020202020207075622063617365205055424c49430a2020202020202020707562206361736520505249564154450a202020207d0a0a20202020707562207265736f7572636520426c6f67207b0a202020202020202070726976206c65742069643a2055496e7433320a202020202020202070726976206c6574207469746c653a20537472696e670a202020202020202070726976206c6574206465736372697074696f6e3a20537472696e670a202020202020202070726976206c657420626f64793a20537472696e670a202020202020202070726976206c657420617574686f723a20537472696e670a202020202020202070726976206c65742062616e6e6572496d673a20537472696e670a202020202020202070726976206c657420747970653a20426c6f67547970650a0a2020202020202020696e69742869643a55496e7433322c207469746c653a20537472696e672c206465736372697074696f6e3a20537472696e672c20626f64793a20537472696e672c20617574686f723a20537472696e672c2062616e6e6572496d673a20537472696e672c20747970653a20426c6f675479706529207b0a20202020202020202020202073656c662e6964203d2069640a20202020202020202020202073656c662e7469746c65203d207469746c650a20202020202020202020202073656c662e6465736372697074696f6e203d206465736372697074696f6e0a20202020202020202020202073656c662e626f6479203d20626f64790a20202020202020202020202073656c662e617574686f72203d20617574686f720a20202020202020202020202073656c662e62616e6e6572496d67203d2062616e6e6572496d670a20202020202020202020202073656c662e74797065203d20747970650a20202020202020207d0a0a202020202020202061636365737328636f6e7472616374292066756e2069735075626c696328293a20426f6f6c207b0a20202020202020202020202072657475726e2073656c662e74797065203d3d20426c6f67547970652e5055424c49430a20202020202020207d0a0a202020202020202061636365737328636f6e7472616374292066756e206765744461746128293a207b537472696e673a537472696e677d207b0a20202020202020202020202072657475726e207b0a20202020202020202020202020202020226964223a2073656c662e69642e746f537472696e6728292c0a20202020202020202020202020202020227469746c65223a2073656c662e7469746c652c0a20202020202020202020202020202020226465736372697074696f6e223a2073656c662e6465736372697074696f6e2c0a2020202020202020202020202020202022626f6479223a2073656c662e626f64792c0a2020202020202020202020202020202022617574686f72223a2073656c662e617574686f722c0a202020202020202020202020202020202262616e6e6572496d67223a2073656c662e62616e6e6572496d672c0a202020202020202020202020202020202274797065223a2073656c662e74797065203d3d20426c6f67547970652e5055424c4943203f20225055424c494322203a202250524956415445220a2020202020202020202020207d0a20202020202020207d0a202020207d0a0a20202020707562207265736f7572636520426c6f67436f6c6c656374696f6e207b0a202020202020202070726976206c6574206f776e6564426c6f67733a20407b55496e7433323a20426c6f677d0a202020202020202070726976207661722073756273637269626572733a207b416464726573733a205546697836347d0a20202020202020207072697620766172206964436f756e743a2055496e7433320a2020202020202020707269762076617220737562736372697074696f6e4475726174696f6e3a205546697836340a0a2020202020202020707269762076617220737562736372697074696f6e436f73743a205546697836343f0a20202020202020207072697620766172206f776e6572416464723a20416464726573730a20202020202020207072697620766172206f776e65724e616d653a20537472696e673f0a20202020202020207072697620766172206f776e65724176617461723a20537472696e673f0a20202020202020207072697620766172206f776e657242696f3a20537472696e673f0a0a2020202020202020696e6974285f206f776e65723a20416464726573732c206e616d653a20537472696e673f2c206176617461723a20537472696e673f2c2062696f3a20537472696e673f2c20737562736372697074696f6e436f73743a205546697836343f29207b0a20202020202020202020202073656c662e6f776e6564426c6f6773203c2d207b7d0a20202020202020202020202073656c662e7375627363726962657273203d207b7d0a20202020202020202020202073656c662e6964436f756e74203d20300a0a2020202020202020202020202f2f20544f444f3a204d616b652074686973206120706172616d65746572206c617465720a2020202020202020202020206c657420737562736372697074696f6e44617973203d2033300a20202020202020202020202073656c662e737562736372697074696f6e4475726174696f6e203d2055466978363428737562736372697074696f6e4461797329202a2032342e30202a2036302e30202a2036302e300a0a20202020202020202020202073656c662e6f776e657241646472203d206f776e65720a20202020202020202020202073656c662e737562736372697074696f6e436f7374203d20737562736372697074696f6e436f73740a20202020202020202020202073656c662e6f776e65724e616d65203d206e616d650a20202020202020202020202073656c662e6f776e6572417661746172203d206176617461720a20202020202020202020202073656c662e6f776e657242696f203d2062696f0a0a20202020202020202020202073656c662e6164645375627363726962657228616464726573733a2073656c662e6f776e6572416464722c2074696d657374616d703a2067657443757272656e74426c6f636b28292e74696d657374616d70290a20202020202020207d0a0a202020202020202061636365737328636f6e7472616374292066756e2061646428626c6f673a40426c6f672c69643a55496e743332297b0a20202020202020202020202073656c662e6f776e6564426c6f67735b69645d3c2d21626c6f673b0a20202020202020207d0a0a202020202020202061636365737328636f6e7472616374292066756e20676574426c6f672869643a55496e743332293a7b537472696e673a537472696e677d7b0a2020202020202020202020206c657420626c6f67203c2d2073656c662e6f776e6564426c6f67732e72656d6f7665286b65793a206964290a0a2020202020202020202020206c65742064617461203d20626c6f673f2e6765744461746128290a0a20202020202020202020202073656c662e6f776e6564426c6f67735b69645d3c2d21626c6f673b0a0a20202020202020202020202072657475726e2064617461210a0a20202020202020207d0a0a202020202020202061636365737328636f6e7472616374292066756e206164645375627363726962657228616464726573733a20416464726573732c2074696d657374616d703a20554669783634297b0a20202020202020202020202073656c662e73756273637269626572735b616464726573735d203d2074696d657374616d700a20202020202020207d0a0a202020202020202061636365737328636f6e7472616374292066756e2072656d6f76655375627363726962657228616464726573733a2041646472657373297b0a20202020202020202020202073656c662e73756273637269626572732e72656d6f7665286b65793a2061646472657373290a20202020202020207d0a0a202020202020202061636365737328636f6e7472616374292066756e20757064617465537562736372697074696f6e436f737428636f73743a20554669783634297b0a20202020202020202020202073656c662e737562736372697074696f6e436f7374203d20636f73740a20202020202020207d0a0a202020202020202061636365737328636f6e7472616374292066756e207570646174654f776e657244657461696c73286e616d653a20537472696e672c206176617461723a20537472696e672c2062696f3a20537472696e672c20737562736372697074696f6e436f73743a20554669783634297b0a20202020202020202020202073656c662e6f776e65724e616d65203d206e616d650a20202020202020202020202073656c662e6f776e6572417661746172203d206176617461720a20202020202020202020202073656c662e6f776e657242696f203d2062696f0a20202020202020202020202073656c662e737562736372697074696f6e436f7374203d20737562736372697074696f6e436f73740a20202020202020207d0a0a202020202020202061636365737328636f6e7472616374292066756e20696e6372656d656e74496428297b0a20202020202020202020202073656c662e6964436f756e74203d2073656c662e6964436f756e74202b20310a20202020202020207d0a0a20202020202020207075622066756e207665726966795369676e2820616464726573733a20416464726573732c206d6573736167653a20537472696e672c207369676e61747572653a20537472696e672c206b6579496e6465783a20496e7420293a20426f6f6c200a20202020202020207b0a0a2020202020202020202020206c6574206163636f756e74203d206765744163636f756e742861646472657373290a2020202020202020202020206c6574207075626c69634b657973203d206163636f756e742e6b6579732e676574286b6579496e6465783a206b6579496e64657829203f3f2070616e696328224e6f206b65792077697468207468617420696e64657820696e206163636f756e7422290a2020202020202020202020206c6574207075626c69634b6579203d207075626c69634b6579732e7075626c69634b65790a0a2020202020202020202020202f2f20436865636b20696620676976656e20537472696e6720697320612076616c69642068657820737472696e670a2020202020202020202020206966206d6573736167652e6c656e6774682025203220213d2030207b0a2020202020202020202020202020202070616e69632822496e76616c6964206d6573736167652068657820737472696e6722290a2020202020202020202020207d0a0a2020202020202020202020206966207369676e61747572652e6c656e6774682025203220213d2030207b0a2020202020202020202020202020202070616e69632822496e76616c6964207369676e61747572652068657820737472696e6722290a2020202020202020202020207d0a0a2020202020202020202020206c6574207369676e203d207369676e61747572652e6465636f646548657828290a2020202020202020202020206c6574206d7367203d206d6573736167652e6465636f646548657828290a0a2020202020202020202020206c657420766572696669636174696f6e526573203d207075626c69634b65792e766572696679280a202020202020202020202020202020207369676e61747572653a207369676e2c0a202020202020202020202020202020207369676e6564446174613a206d73672c0a202020202020202020202020202020202f2f20646f6d61696e53657061726174696f6e5461673a2022222c0a20202020202020202020202020202020646f6d61696e53657061726174696f6e5461673a2022464c4f572d56302e302d75736572222c0a2020202020202020202020202020202068617368416c676f726974686d3a2048617368416c676f726974686d2e534841335f3235360a202020202020202020202020290a0a20202020202020202020202069662021766572696669636174696f6e526573207b0a2020202020202020202020202020202072657475726e2066616c73650a2020202020202020202020207d0a0a2020202020202020202020206c6574206d736754657874203d2073656c662e686578546f54657874286865783a206d657373616765290a2020202020202020202020206c6574206d736754696d657374616d70203d205546697836342e66726f6d537472696e67286d736754657874290a0a2020202020202020202020206966206d736754696d657374616d70203d3d206e696c207b0a2020202020202020202020202020202072657475726e2066616c73650a2020202020202020202020207d0a0a2020202020202020202020206c65742063757272656e7454696d657374616d70203d2067657443757272656e74426c6f636b28292e74696d657374616d703b0a2020202020202020202020200a2020202020202020202020206966206d736754696d657374616d7021203e2063757272656e7454696d657374616d70207b0a2020202020202020202020202020202072657475726e2066616c73650a2020202020202020202020207d0a0a2020202020202020202020206966202863757272656e7454696d657374616d70202d206d736754696d657374616d702129203e2039302e30207b0a2020202020202020202020202020202072657475726e2066616c73650a2020202020202020202020207d0a0a20202020202020202020202072657475726e20747275650a0a20202020202020207d0a0a20202020202020207075622066756e20686578546f54657874286865783a20537472696e67293a20537472696e67200a20202020202020207b0a2020202020202020202020206c6574206c656e677468203d206865782e6c656e6774680a0a2020202020202020202020206c65742063686172616374657244696374696f6e617279203d207b0a20202020202020202020202020202020223030223a20225c757b303030307d222c0a20202020202020202020202020202020223031223a20225c757b303030317d222c0a20202020202020202020202020202020223032223a20225c757b303030327d222c0a20202020202020202020202020202020223033223a20225c757b303030337d222c0a20202020202020202020202020202020223034223a20225c757b303030347d222c0a20202020202020202020202020202020223035223a20225c757b303030357d222c0a20202020202020202020202020202020223036223a20225c757b303030367d222c0a20202020202020202020202020202020223037223a20225c757b303030377d222c0a20202020202020202020202020202020223038223a20225c757b303030387d222c0a20202020202020202020202020202020223039223a20225c757b303030397d222c0a20202020202020202020202020202020223061223a20225c757b303030417d222c0a20202020202020202020202020202020223062223a20225c757b303030427d222c0a20202020202020202020202020202020223063223a20225c757b303030437d222c0a20202020202020202020202020202020223064223a20225c757b303030447d222c0a20202020202020202020202020202020223065223a20225c757b303030457d222c0a20202020202020202020202020202020223066223a20225c757b303030467d222c0a20202020202020202020202020202020223130223a20225c757b303031307d222c0a20202020202020202020202020202020223131223a20225c757b303031317d222c0a20202020202020202020202020202020223132223a20225c757b303031327d222c0a20202020202020202020202020202020223133223a20225c757b303031337d222c0a20202020202020202020202020202020223134223a20225c757b303031347d222c0a20202020202020202020202020202020223135223a20225c757b303031357d222c0a20202020202020202020202020202020223136223a20225c757b303031367d222c0a20202020202020202020202020202020223137223a20225c757b303031377d222c0a20202020202020202020202020202020223138223a20225c757b303031387d222c0a20202020202020202020202020202020223139223a20225c757b303031397d222c0a20202020202020202020202020202020223161223a20225c757b303031417d222c0a20202020202020202020202020202020223162223a20225c757b303031427d222c0a20202020202020202020202020202020223163223a20225c757b303031437d222c0a20202020202020202020202020202020223164223a20225c757b303031447d222c0a20202020202020202020202020202020223165223a20225c757b303031457d222c0a20202020202020202020202020202020223166223a20225c757b303031467d222c0a20202020202020202020202020202020223230223a202220222c0a20202020202020202020202020202020223231223a202221222c0a20202020202020202020202020202020223232223a20225c22222c0a20202020202020202020202020202020223233223a202223222c0a20202020202020202020202020202020223234223a202224222c0a20202020202020202020202020202020223235223a202225222c0a20202020202020202020202020202020223236223a202226222c0a20202020202020202020202020202020223237223a202227222c0a20202020202020202020202020202020223238223a202228222c0a20202020202020202020202020202020223239223a202229222c0a20202020202020202020202020202020223261223a20222a222c0a20202020202020202020202020202020223262223a20222b222c0a20202020202020202020202020202020223263223a20222c222c0a20202020202020202020202020202020223264223a20222d222c0a20202020202020202020202020202020223265223a20222e222c0a20202020202020202020202020202020223266223a20222f222c0a20202020202020202020202020202020223330223a202230222c0a20202020202020202020202020202020223331223a202231222c0a20202020202020202020202020202020223332223a202232222c0a20202020202020202020202020202020223333223a202233222c0a20202020202020202020202020202020223334223a202234222c0a20202020202020202020202020202020223335223a202235222c0a20202020202020202020202020202020223336223a202236222c0a20202020202020202020202020202020223337223a202237222c0a20202020202020202020202020202020223338223a202238222c0a20202020202020202020202020202020223339223a202239222c0a20202020202020202020202020202020223361223a20223a222c0a20202020202020202020202020202020223362223a20223b222c0a20202020202020202020202020202020223363223a20223c222c0a20202020202020202020202020202020223364223a20223d222c0a20202020202020202020202020202020223365223a20223e222c0a20202020202020202020202020202020223366223a20223f222c0a20202020202020202020202020202020223430223a202240222c0a20202020202020202020202020202020223431223a202241222c0a20202020202020202020202020202020223432223a202242222c0a20202020202020202020202020202020223433223a202243222c0a20202020202020202020202020202020223434223a202244222c0a20202020202020202020202020202020223435223a202245222c0a20202020202020202020202020202020223436223a202246222c0a20202020202020202020202020202020223437223a202247222c0a20202020202020202020202020202020223438223a202248222c0a20202020202020202020202020202020223439223a202249222c0a20202020202020202020202020202020223461223a20224a222c0a20202020202020202020202020202020223462223a20224b222c0a20202020202020202020202020202020223463223a20224c222c0a20202020202020202020202020202020223464223a20224d222c0a20202020202020202020202020202020223465223a20224e222c0a20202020202020202020202020202020223466223a20224f222c0a20202020202020202020202020202020223530223a202250222c0a20202020202020202020202020202020223531223a202251222c0a20202020202020202020202020202020223532223a202252222c0a20202020202020202020202020202020223533223a202253222c0a20202020202020202020202020202020223534223a202254222c0a20202020202020202020202020202020223535223a202255222c0a20202020202020202020202020202020223536223a202256222c0a20202020202020202020202020202020223537223a202257222c0a20202020202020202020202020202020223538223a202258222c0a20202020202020202020202020202020223539223a202259222c0a20202020202020202020202020202020223561223a20225a222c0a20202020202020202020202020202020223562223a20225b222c0a20202020202020202020202020202020223563223a20225c5c222c0a20202020202020202020202020202020223564223a20225d222c0a20202020202020202020202020202020223565223a20225e222c0a20202020202020202020202020202020223566223a20225f222c0a20202020202020202020202020202020223630223a202260222c0a20202020202020202020202020202020223631223a202261222c0a20202020202020202020202020202020223632223a202262222c0a20202020202020202020202020202020223633223a202263222c0a20202020202020202020202020202020223634223a202264222c0a20202020202020202020202020202020223635223a202265222c0a20202020202020202020202020202020223636223a202266222c0a20202020202020202020202020202020223637223a202267222c0a20202020202020202020202020202020223638223a202268222c0a20202020202020202020202020202020223639223a202269222c0a20202020202020202020202020202020223661223a20226a222c0a20202020202020202020202020202020223662223a20226b222c0a20202020202020202020202020202020223663223a20226c222c0a20202020202020202020202020202020223664223a20226d222c0a20202020202020202020202020202020223665223a20226e222c0a20202020202020202020202020202020223666223a20226f222c0a20202020202020202020202020202020223730223a202270222c0a20202020202020202020202020202020223731223a202271222c0a20202020202020202020202020202020223732223a202272222c0a20202020202020202020202020202020223733223a202273222c0a20202020202020202020202020202020223734223a202274222c0a20202020202020202020202020202020223735223a202275222c0a20202020202020202020202020202020223736223a202276222c0a20202020202020202020202020202020223737223a202277222c0a20202020202020202020202020202020223738223a202278222c0a20202020202020202020202020202020223739223a202279222c0a20202020202020202020202020202020223761223a20227a222c0a20202020202020202020202020202020223762223a20227b222c0a20202020202020202020202020202020223763223a20227c222c0a20202020202020202020202020202020223764223a20227d222c0a20202020202020202020202020202020223765223a20227e222c0a20202020202020202020202020202020223766223a20225c757b303037467d220a2020202020202020202020207d0a0a20202020202020202020202076617220726573203d2022223b0a2020202020202020202020207661722069203d20300a0a2020202020202020202020207768696c652069203c20286c656e6774682f3229207b0a202020202020202020202020202020206c6574207374617274496e646578203d2069202a20320a202020202020202020202020202020206c657420656e64496e646578203d207374617274496e646578202b20320a202020202020202020202020202020206c657420737562737472696e67203d206865782e736c6963652866726f6d3a207374617274496e6465782c207570546f3a20656e64496e646578290a202020202020202020202020202020206c657420636861726163746572203d2063686172616374657244696374696f6e6172795b737562737472696e675d203f3f2070616e69632822496e76616c69642068657820737472696e67206f7220696e76616c69642063686172616374657220636f64653a203078222e636f6e63617428737562737472696e6729290a202020202020202020202020202020200a20202020202020202020202020202020726573203d207265732e636f6e63617428636861726163746572290a2020202020202020202020202020202069203d2069202b20310a2020202020202020202020207d0a0a2020202020202020202020206c6574207265734c656e203d207265732e6c656e6774680a0a20202020202020202020202072657475726e207265732e736c6963652866726f6d3a2033322c207570546f3a207265734c656e290a20202020202020207d0a0a20202020202020207075622066756e206765744964436f756e7428293a2055496e7433327b0a20202020202020202020202072657475726e2073656c662e6964436f756e743b0a20202020202020207d0a0a20202020202020207075622066756e206765744b65797328293a5b55496e7433325d7b0a20202020202020202020202072657475726e2073656c662e6f776e6564426c6f67732e6b6579733b0a20202020202020207d0a0a20202020202020207075622066756e20676574537562736372696265727328293a7b416464726573733a205546697836347d7b0a20202020202020202020202072657475726e2073656c662e73756273637269626572733b0a20202020202020207d0a0a20202020202020207075622066756e20676574537562736372697074696f6e436f737428293a205546697836347b0a20202020202020202020202072657475726e2073656c662e737562736372697074696f6e436f7374213b0a20202020202020207d0a0a20202020202020207075622066756e206973436f73744e696c28293a20426f6f6c7b0a20202020202020202020202072657475726e2073656c662e737562736372697074696f6e436f7374203d3d206e696c3b0a20202020202020207d0a0a20202020202020207075622066756e206765744f776e657228293a416464726573737b0a20202020202020202020202072657475726e2073656c662e6f776e6572416464723b0a20202020202020207d0a0a20202020202020207075622066756e206765744f776e6572496e666f28293a7b537472696e673a537472696e677d7b0a20202020202020202020202072657475726e207b0a202020202020202020202020202020202261646472657373223a2073656c662e6f776e6572416464722e746f537472696e6728292c0a20202020202020202020202020202020226e616d65223a2073656c662e6f776e65724e616d65203f3f2022222c0a2020202020202020202020202020202022617661746172223a2073656c662e6f776e6572417661746172203f3f2022222c0a202020202020202020202020202020202262696f223a2073656c662e6f776e657242696f203f3f2022222c0a2020202020202020202020202020202022737562736372697074696f6e436f7374223a2073656c662e737562736372697074696f6e436f7374212e746f537472696e6728290a2020202020202020202020207d0a20202020202020207d0a0a20202020202020207075622066756e20676574537562736372697074696f6e4475726174696f6e28293a205546697836347b0a20202020202020202020202072657475726e2073656c662e737562736372697074696f6e4475726174696f6e3b0a20202020202020207d0a0a20202020202020207075622066756e2069735375627363726962656428616464726573733a2041646472657373293a20426f6f6c7b0a2020202020202020202020206c657420737562736372696265644174203d2073656c662e73756273637269626572735b616464726573735d203f3f20302e303b0a0a202020202020202020202020696620737562736372696265644174203d3d20302e30207b200a2020202020202020202020202020202072657475726e2066616c73653b0a2020202020202020202020207d0a0a20202020202020202020202069662061646472657373203d3d2073656c662e6f776e657241646472207b0a2020202020202020202020202020202072657475726e20747275653b0a2020202020202020202020207d0a0a2020202020202020202020206c6574206e6f77203d2067657443757272656e74426c6f636b28292e74696d657374616d703b0a0a2020202020202020202020206966206e6f77202d20737562736372696265644174203e2073656c662e737562736372697074696f6e4475726174696f6e207b0a2020202020202020202020202020202072657475726e2066616c73653b0a2020202020202020202020207d0a0a20202020202020202020202072657475726e20747275653b0a20202020202020207d0a0a20202020202020207075622066756e20676574426c6f67427949642869643a55496e7433322c20616464726573733a20416464726573732c206d6573736167653a20537472696e672c207369676e61747572653a20537472696e672c206b6579496e6465783a20496e74293a207b537472696e673a20537472696e677d3f207b0a0a2020202020202020202020206966202173656c662e69735375627363726962656428616464726573733a206164647265737329207b0a2020202020202020202020202020202072657475726e206e696c0a2020202020202020202020207d0a0a2020202020202020202020206966202173656c662e7665726966795369676e28616464726573733a20616464726573732c206d6573736167653a206d6573736167652c207369676e61747572653a207369676e61747572652c206b6579496e6465783a206b6579496e64657829207b0a2020202020202020202020202020202072657475726e206e696c0a2020202020202020202020207d0a0a20202020202020202020202069662073656c662e6973436f73744e696c2829207b0a2020202020202020202020202020202070616e69632822537562736372697074696f6e20636f7374206e6f7420736574206279206f776e657222290a2020202020202020202020207d0a0a2020202020202020202020206c657420626c6f67203d2073656c662e676574426c6f672869643a6964293b0a0a202020202020202020202020696620626c6f67203d3d206e696c207b0a2020202020202020202020202020202070616e69632822426c6f67206e6f7420666f756e6422290a2020202020202020202020207d0a0a20202020202020202020202072657475726e20626c6f673b0a0a20202020202020207d0a0a20202020202020207075622066756e20676574416c6c426c6f677328616464726573733a20416464726573732c206d6573736167653a20537472696e672c207369676e61747572653a20537472696e672c206b6579496e6465783a20496e74293a205b7b537472696e673a537472696e677d5d3f207b0a0a2020202020202020202020206966202173656c662e69735375627363726962656428616464726573733a206164647265737329207b0a2020202020202020202020202020202072657475726e206e696c3b0a2020202020202020202020207d0a0a2020202020202020202020206966202173656c662e7665726966795369676e28616464726573733a20616464726573732c206d6573736167653a206d6573736167652c207369676e61747572653a207369676e61747572652c206b6579496e6465783a206b6579496e64657829207b0a2020202020202020202020202020202072657475726e206e696c3b0a2020202020202020202020207d0a0a20202020202020202020202069662073656c662e6973436f73744e696c2829207b0a2020202020202020202020202020202070616e69632822537562736372697074696f6e20636f7374206e6f7420736574206279206f776e657222290a2020202020202020202020207d0a0a2020202020202020202020206c6574206b657973203d2073656c662e6765744b65797328293b0a0a20202020202020202020202076617220626c6f67733a205b7b537472696e673a537472696e677d5d203d205b5d3b0a0a202020202020202020202020666f72206b657920696e206b657973207b0a202020202020202020202020202020206c657420626c6f67203d2073656c662e676574426c6f672869643a6b6579293b0a20202020202020202020202020202020626c6f67732e617070656e6428626c6f67290a2020202020202020202020207d0a0a20202020202020202020202072657475726e20626c6f67733b0a20202020202020207d0a0a202020202020202064657374726f79202829207b0a20202020202020202020202064657374726f792073656c662e6f776e6564426c6f67730a20202020202020207d0a0a202020207d0a0a202020207075622066756e20637265617465456d707479436f6c6c656374696f6e28293a2040426c6f67436f6c6c656374696f6e7b0a202020202020202072657475726e203c2d2063726561746520426c6f67436f6c6c656374696f6e2873656c662e6163636f756e742e616464726573732c206e616d653a206e696c2c206176617461723a206e696c2c2062696f3a206e696c2c20737562736372697074696f6e436f73743a206e696c290a202020207d0a0a2020202061636365737328636f6e7472616374292066756e206164645375627363726962657228616464726573733a20416464726573732c2074696d657374616d703a20554669783634297b0a20202020202020202f2f2067657420746865207075626c6963206361706162696c6974790a20202020202020206c6574207075626c69634361706162696c697479203d2073656c662e6163636f756e742e6765744361706162696c6974793c26426c6f67436f6c6c656374696f6e3e2873656c662e426c6f67436f6c6c656374696f6e5075626c696350617468292e626f72726f772829203f3f2070616e69632822436f756c64206e6f7420626f72726f77206361706162696c69747922293b0a0a20202020202020202f2f20626f72726f772074686520636f6c6c656374696f6e0a20202020202020207075626c69634361706162696c6974792e6164645375627363726962657228616464726573733a20616464726573732c2074696d657374616d703a2074696d657374616d70290a202020207d0a0a2020202061636365737328636f6e7472616374292066756e2072656d6f76655375627363726962657228616464726573733a2041646472657373297b200a20202020202020202f2f2067657420746865207075626c6963206361706162696c6974790a20202020202020206c6574207075626c69634361706162696c6974793a2026426c6f674d616e616765722e426c6f67436f6c6c656374696f6e203d2073656c662e6163636f756e742e6765744361706162696c6974793c26426c6f67436f6c6c656374696f6e3e2873656c662e426c6f67436f6c6c656374696f6e5075626c696350617468292e626f72726f772829203f3f2070616e69632822436f756c64206e6f7420626f72726f77206361706162696c69747922293b0a0a20202020202020202f2f20626f72726f772074686520636f6c6c656374696f6e0a20202020202020207075626c69634361706162696c6974792e72656d6f76655375627363726962657228616464726573733a2061646472657373290a202020207d0a0a202020207075622066756e2075706461746544657461696c73286e616d653a20537472696e672c206176617461723a20537472696e672c2062696f3a20537472696e672c20737562736372697074696f6e436f73743a205546697836342c20626c6f67436f6c6c656374696f6e3a2026426c6f67436f6c6c656374696f6e29203a20426f6f6c7b0a2020202020202020696620626c6f67436f6c6c656374696f6e2e6765744f776e6572282920213d2073656c662e6163636f756e742e61646472657373207b0a20202020202020202020202070616e69632822596f7520617265206e6f7420746865206f776e6572206f66207468697320636f6c6c656374696f6e22290a20202020202020207d0a0a2020202020202020626c6f67436f6c6c656374696f6e2e757064617465537562736372697074696f6e436f737428636f73743a20737562736372697074696f6e436f7374290a0a2020202020202020626c6f67436f6c6c656374696f6e2e7570646174654f776e657244657461696c73286e616d653a206e616d652c206176617461723a206176617461722c2062696f3a2062696f2c20737562736372697074696f6e436f73743a20737562736372697074696f6e436f7374290a0a202020202020202072657475726e20747275650a20202020202020200a202020207d0a0a202020207075622066756e20637265617465426c6f67287469746c653a20537472696e672c206465736372697074696f6e3a20537472696e672c20626f64793a20537472696e672c20617574686f723a20537472696e672c2062616e6e6572496d673a20537472696e672c20747970653a20426c6f67547970652c20626c6f67436f6c6c656374696f6e3a2026426c6f67436f6c6c656374696f6e29207b0a0a2020202020202020696620626c6f67436f6c6c656374696f6e2e6765744f776e6572282920213d2073656c662e6163636f756e742e61646472657373207b0a20202020202020202020202070616e69632822596f7520617265206e6f7420746865206f776e6572206f66207468697320636f6c6c656374696f6e22290a20202020202020207d0a0a2020202020202020696620626c6f67436f6c6c656374696f6e2e6973436f73744e696c2829207b0a20202020202020202020202070616e69632822506c6561736520736574206120737562736372697074696f6e20636f737420666f7220796f757220626c6f6720636f6c6c656374696f6e22290a20202020202020207d0a0a2020202020202020626c6f67436f6c6c656374696f6e2e696e6372656d656e74496428290a20202020202020206c6574206e6577426c6f673a2040426c6f674d616e616765722e426c6f67203c2d2063726561746520426c6f672869643a626c6f67436f6c6c656374696f6e2e6765744964436f756e7428292c7469746c653a7469746c652c6465736372697074696f6e3a6465736372697074696f6e2c626f64793a626f64792c617574686f723a617574686f722c2062616e6e6572496d673a2062616e6e6572496d672c20747970653a2074797065290a0a20202020202020206c657420636f6c6c656374696f6e3a2026426c6f674d616e616765722e426c6f67436f6c6c656374696f6e3f203d2073656c662e6163636f756e742e626f72726f773c26426c6f67436f6c6c656374696f6e3e2866726f6d3a2073656c662e426c6f67436f6c6c656374696f6e53746f7261676550617468293b0a20202020202020200a2020202020202020636f6c6c656374696f6e212e61646428626c6f673a3c2d6e6577426c6f672c69643a626c6f67436f6c6c656374696f6e2e6765744964436f756e742829293b0a202020207d0a0a202020207075622066756e20676574426c6f674d6574616461746128293a5b7b537472696e673a537472696e677d5d7b0a20202020202020206c657420636f6c6c656374696f6e203d2073656c662e6163636f756e742e626f72726f773c26426c6f67436f6c6c656374696f6e3e2866726f6d3a2073656c662e426c6f67436f6c6c656374696f6e53746f726167655061746829203f3f2070616e69632822436f756c64206e6f7420626f72726f77206361706162696c69747922293b0a0a20202020202020206c6574206b657973203d20636f6c6c656374696f6e2e6765744b65797328293b0a0a202020202020202076617220626c6f67733a205b7b537472696e673a537472696e677d5d203d205b5d3b0a0a2020202020202020666f72206b657920696e206b657973207b0a2020202020202020202020206c657420626c6f67203d20636f6c6c656374696f6e2e676574426c6f672869643a6b6579293b0a20202020202020202020202069662028626c6f675b2274797065225d20213d20225055424c49432229207b0a20202020202020202020202020202020626c6f672e72656d6f7665286b65793a2022626f647922290a2020202020202020202020207d0a202020202020202020202020626c6f67732e617070656e6428626c6f67290a20202020202020207d0a0a202020202020202072657475726e20626c6f67733b0a202020207d0a0a202020207075622066756e20737562736372696265285f20616464726573733a20416464726573732c207661756c743a204046756e6769626c65546f6b656e2e5661756c742c20737562736372697074696f6e733a2026537562736372697074696f6e734d616e616765722e537562736372697074696f6e737b537562736372697074696f6e734d616e616765722e537562736372697074696f6e73507269767d29203a20426f6f6c207b0a20202020202020206c657420626c6f676765724361706162696c697479203d2073656c662e6163636f756e742e6765744361706162696c6974793c26426c6f674d616e616765722e426c6f67436f6c6c656374696f6e3e28426c6f674d616e616765722e426c6f67436f6c6c656374696f6e5075626c696350617468292e626f72726f772829203f3f2070616e69632822436f756c64206e6f7420626f72726f77206361706162696c69747922290a0a2020202020202020696620626c6f676765724361706162696c6974792e6973436f73744e696c2829207b0a20202020202020202020202070616e69632822537562736372697074696f6e20636f7374206e6f742073657422290a20202020202020207d0a0a20202020202020206966207661756c742e62616c616e636520213d20626c6f676765724361706162696c6974792e676574537562736372697074696f6e436f73742829207b0a20202020202020202020202070616e69632822496e636f727265637420616d6f756e742073656e7422290a20202020202020207d0a0a20202020202020202f2f206966206164647265737320697320616c726561647920737562736372696265640a202020202020202069662073656c662e69735375627363726962656428616464726573733a206164647265737329207b0a20202020202020202020202070616e69632822416c7265616479207375627363726962656422290a20202020202020207d0a0a20202020202020206c6574206465706f7369744361706162696c697479203d2073656c662e6163636f756e742e6765744361706162696c6974793c267b46756e6769626c65546f6b656e2e52656365697665727d3e2873656c662e466c6f77546f6b656e5661756c7450617468292e626f72726f772829203f3f2070616e69632822436f756c64206e6f7420626f72726f77206361706162696c69747922290a0a0a20202020202020206465706f7369744361706162696c6974792e6465706f7369742866726f6d3a203c2d207661756c74290a20202020202020206c65742074696d657374616d703a20554669783634203d2067657443757272656e74426c6f636b28292e74696d657374616d703b0a202020202020202073656c662e6164645375627363726962657228616464726573733a20616464726573732c2074696d657374616d703a2074696d657374616d70290a2020202020202020537562736372697074696f6e734d616e616765722e73756273637269626528626c6f676765723a20616464726573732c207265616465723a20616464726573732c20737562736372697074696f6e733a20737562736372697074696f6e73290a0a202020202020202072657475726e20747275650a20202020202020200a202020207d0a0a202020207075622066756e20756e73756273637269626528726561646572416464723a20416464726573732c20737562736372697074696f6e733a2026537562736372697074696f6e734d616e616765722e537562736372697074696f6e737b537562736372697074696f6e734d616e616765722e537562736372697074696f6e73507269767d29203a20426f6f6c207b0a20202020202020206966202173656c662e69735375627363726962656428616464726573733a207265616465724164647229207c7c20737562736372697074696f6e732e676574537562736372696265724964282920213d2072656164657241646472207b0a20202020202020202020202070616e696328224e6f74207375627363726962656422290a20202020202020207d0a0a202020202020202069662073656c662e6163636f756e742e61646472657373203d3d20737562736372697074696f6e732e6765745375627363726962657249642829207b0a20202020202020202020202070616e6963282243616e6e6f7420756e7375627363726962652066726f6d20796f7572206f776e20626c6f6722290a20202020202020207d0a0a202020202020202073656c662e72656d6f76655375627363726962657228616464726573733a2072656164657241646472290a0a202020202020202072657475726e20747275650a202020207d0a0a202020207075622066756e20676574537562736372696265727328293a7b416464726573733a205546697836347d207b0a20202020202020206c657420636f6c6c656374696f6e203d2073656c662e6163636f756e742e626f72726f773c26426c6f67436f6c6c656374696f6e3e2866726f6d3a2073656c662e426c6f67436f6c6c656374696f6e53746f7261676550617468293b0a202020202020202072657475726e20636f6c6c656374696f6e212e676574537562736372696265727328293b0a202020207d0a0a202020207075622066756e2069735375627363726962656428616464726573733a2041646472657373293a20426f6f6c7b0a20202020202020206c657420636f6c6c656374696f6e203d2073656c662e6163636f756e742e626f72726f773c26426c6f67436f6c6c656374696f6e3e2866726f6d3a2073656c662e426c6f67436f6c6c656374696f6e53746f726167655061746829203f3f2070616e69632822436f756c64206e6f7420626f72726f77206361706162696c69747922293b0a202020202020202072657475726e20636f6c6c656374696f6e2e69735375627363726962656428616464726573733a2061646472657373293b0a202020207d0a0a20202020696e69742829207b0a202020202020202073656c662e426c6f67436f6c6c656374696f6e53746f7261676550617468203d202f73746f726167652f426c6f67436f6c6c656374696f6e0a202020202020202073656c662e426c6f67436f6c6c656374696f6e5075626c696350617468203d202f7075626c69632f426c6f67436f6c6c656374696f6e0a0a202020202020202073656c662e537562736372697074696f6e7353746f7261676550617468203d20537562736372697074696f6e734d616e616765722e537562736372697074696f6e7353746f72616765506174683b0a202020202020202073656c662e537562736372697074696f6e735075626c696350617468203d20537562736372697074696f6e734d616e616765722e537562736372697074696f6e735075626c6963506174683b0a202020202020202073656c662e537562736372697074696f6e735072697661746550617468203d20537562736372697074696f6e734d616e616765722e537562736372697074696f6e7350726976617465506174683b0a0a202020202020202073656c662e466c6f77546f6b656e5661756c7450617468203d202f7075626c69632f666c6f77546f6b656e52656365697665720a0a20202020202020206c657420636f6c6c656374696f6e436f6e646974696f6e73203d205b0a20202020202020202020202073656c662e6163636f756e742e73746f7261676550617468732e636f6e7461696e732873656c662e426c6f67436f6c6c656374696f6e53746f7261676550617468292c0a20202020202020202020202073656c662e6163636f756e742e6765744361706162696c6974793c26426c6f67436f6c6c656374696f6e3e2873656c662e426c6f67436f6c6c656374696f6e5075626c696350617468292e636865636b28290a20202020202020205d0a0a2020202020202020696620636f6c6c656374696f6e436f6e646974696f6e732e636f6e7461696e73287472756529207b0a20202020202020202020202070616e69632822496e76616c696420426c6f67436f6c6c656374696f6e20636f6e747261637422290a20202020202020207d0a202020202020202073656c662e6163636f756e742e73617665283c2d73656c662e637265617465456d707479436f6c6c656374696f6e28292c20746f3a2073656c662e426c6f67436f6c6c656374696f6e53746f7261676550617468290a202020202020202073656c662e6163636f756e742e6c696e6b3c26426c6f67436f6c6c656374696f6e3e2873656c662e426c6f67436f6c6c656374696f6e5075626c6963506174682c20746172676574203a73656c662e426c6f67436f6c6c656374696f6e53746f7261676550617468290a0a20202020202020206c657420737562736372697074696f6e73436f6e646974696f6e73203d205b0a20202020202020202020202073656c662e6163636f756e742e73746f7261676550617468732e636f6e7461696e7328537562736372697074696f6e734d616e616765722e537562736372697074696f6e7353746f7261676550617468292c0a20202020202020202020202073656c662e6163636f756e742e6765744361706162696c6974793c26537562736372697074696f6e734d616e616765722e537562736372697074696f6e737b537562736372697074696f6e734d616e616765722e537562736372697074696f6e735075627d3e28537562736372697074696f6e734d616e616765722e537562736372697074696f6e735075626c696350617468292e636865636b28292c0a20202020202020202020202073656c662e6163636f756e742e6765744361706162696c6974793c26537562736372697074696f6e734d616e616765722e537562736372697074696f6e737b537562736372697074696f6e734d616e616765722e537562736372697074696f6e73507269767d3e28537562736372697074696f6e734d616e616765722e537562736372697074696f6e735072697661746550617468292e636865636b28290a20202020202020205d0a0a2020202020202020696620737562736372697074696f6e73436f6e646974696f6e732e636f6e7461696e73287472756529207b0a0a202020202020202020202020696620737562736372697074696f6e73436f6e646974696f6e735b305d20262620737562736372697074696f6e73436f6e646974696f6e735b315d20262620737562736372697074696f6e73436f6e646974696f6e735b325d207b0a202020202020202020202020202020200a202020202020202020202020202020206c65742063617061203d2073656c662e6163636f756e742e6765744361706162696c6974793c26537562736372697074696f6e734d616e616765722e537562736372697074696f6e737b537562736372697074696f6e734d616e616765722e537562736372697074696f6e73507269767d3e2873656c662e537562736372697074696f6e735072697661746550617468292e626f72726f772829203f3f2070616e69632822436f756c64206e6f7420626f72726f77206361706162696c69747920537562736372697074696f6e732066726f6d20426c6f676765722773207075626c6963207061746822290a20202020202020202020202020202020537562736372697074696f6e734d616e616765722e73756273637269626528626c6f676765723a2073656c662e6163636f756e742e616464726573732c207265616465723a73656c662e6163636f756e742e616464726573732c20737562736372697074696f6e733a2063617061290a2020202020202020202020207d0a202020202020202020202020656c7365207b0a2020202020202020202020202020202070616e69632822496e76616c696420537562736372697074696f6e734d616e6167657220636f6e747261637422290a2020202020202020202020207d0a0a20202020202020207d0a2020202020202020656c7365207b0a20202020202020202020202073656c662e6163636f756e742e73617665283c2d537562736372697074696f6e734d616e616765722e637265617465456d707479537562736372697074696f6e732873656c662e6163636f756e742e61646472657373292c20746f3a2073656c662e537562736372697074696f6e7353746f7261676550617468290a20202020202020202020202073656c662e6163636f756e742e6c696e6b3c26537562736372697074696f6e734d616e616765722e537562736372697074696f6e737b537562736372697074696f6e734d616e616765722e537562736372697074696f6e735075627d3e2873656c662e537562736372697074696f6e735075626c6963506174682c20746172676574203a73656c662e537562736372697074696f6e7353746f7261676550617468290a20202020202020202020202073656c662e6163636f756e742e6c696e6b3c26537562736372697074696f6e734d616e616765722e537562736372697074696f6e737b537562736372697074696f6e734d616e616765722e537562736372697074696f6e73507269767d3e2873656c662e537562736372697074696f6e7350726976617465506174682c20746172676574203a73656c662e537562736372697074696f6e7353746f7261676550617468290a2020202020202020202020206c65742063617061203d2073656c662e6163636f756e742e6765744361706162696c6974793c26537562736372697074696f6e734d616e616765722e537562736372697074696f6e737b537562736372697074696f6e734d616e616765722e537562736372697074696f6e73507269767d3e2873656c662e537562736372697074696f6e735072697661746550617468292e626f72726f772829203f3f2070616e69632822436f756c64206e6f7420626f72726f77206361706162696c69747920537562736372697074696f6e732066726f6d20426c6f676765722773207075626c6963207061746822290a0a202020202020202020202020537562736372697074696f6e734d616e616765722e73756273637269626528626c6f676765723a2073656c662e6163636f756e742e616464726573732c207265616465723a73656c662e6163636f756e742e616464726573732c20737562736372697074696f6e733a2063617061290a20202020202020207d0a0a097d0a7d0a".decodeHex()
        // Check if the contract name already exists
        if (existingContracts.contains("BlogManager")) {
            // If it does, throw an error
            panic("Contract with name BlogManager already exists")
        }

        // Create a new contract with the name BlogManager
        signer.contracts.add(name: "BlogManager", code: BlogManager)

        log("Contract deployed successfully. Please set owner details & subscription amount")
    }
}
`;
export const Subscribe = `

import FungibleToken from 0xFungibleToken
import FlowToken from 0xFlowToken
import BlogManager from 0xBlogger // address of the blogger account
import SubscriptionsManager from 0xDeployer // address of the global subscriber account

transaction(amount: UFix64) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault
    let signerAddress: Address
    let subscriptionsPrivate: &SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}

    prepare(signer: AuthAccount) {
        self.signerAddress = signer.address

        if signer.borrow<&SubscriptionsManager.Subscriptions>(from: SubscriptionsManager.SubscriptionsStoragePath) == nil {
            // Create a new empty subscriptions collection
            signer.save(<- SubscriptionsManager.createEmptySubscriptions(self.signerAddress), to: SubscriptionsManager.SubscriptionsStoragePath)
            // Create public capability for the subscriptions collection
            signer.link<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPub}>(SubscriptionsManager.SubscriptionsPublicPath, target: SubscriptionsManager.SubscriptionsStoragePath)
            // Create private capability for the subscriptions collection
            signer.link<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}>(SubscriptionsManager.SubscriptionsPrivatePath, target: SubscriptionsManager.SubscriptionsStoragePath)
        }

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)

        self.subscriptionsPrivate 
            = signer.getCapability(SubscriptionsManager.SubscriptionsPrivatePath)
                .borrow<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPriv}>()
                ?? panic("Could not borrow capability from public storage")

    }

    execute {
        if BlogManager.subscribe(self.signerAddress, vault: <- self.sentVault, subscriptions: self.subscriptionsPrivate){
            log("Subscribed to blog")
        }
        else {
            log("Failed to subscribe to blog")
        }
    }

}
`;
export const SetOwnerDetails = `
import BlogManager from 0xBlogger

transaction(name: String, avatar: String, bio: String, subscriptionCost: UFix64) {
    let signerAddr: Address
    prepare(signer: AuthAccount ){

        self.signerAddr = signer.address
        
    }
    execute{

        let signer = getAccount(self.signerAddr)
        if signer.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() == nil {
            panic("Signer is not a Blogger")
        }

        let blogCollectionRef = signer.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Signer is not a Blogger")

        BlogManager.updateDetails(name: name, avatar: avatar, bio: bio, subscriptionCost: subscriptionCost, blogCollection: blogCollectionRef)
        
    }
}
`;
export const getOwnerInfo = `
import BlogManager from 0xBlogger

pub fun main(): {String: String}
{
    let account = getAccount(0xBlogger)

    let capa = account.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability from public collection")

    let ownerInfo = capa.getOwnerInfo()

    return ownerInfo

}

`;
export const getSubscriptions = `
import SubscriptionsManager from 0xDeployer // address of the global subscriber account

pub fun main(reader:Address): [Address] {

    let account = getAccount(reader)
    let capa = account.getCapability<&SubscriptionsManager.Subscriptions{SubscriptionsManager.SubscriptionsPub}>(SubscriptionsManager.SubscriptionsPublicPath).borrow() ?? panic("Could not borrow capability")

    let subs = capa.getSubscriptions()

    return subs

}


`;
export const getBlog = `
import BlogManager from 0xBlogger

pub fun main(id: UInt32, address: Address, message: String, signature: String, keyIndex: Int): {String: String}? {

    let account = getAccount(0xBlogger)

    let capa = account.getCapability<&BlogManager.BlogCollection>(BlogManager.BlogCollectionPublicPath).borrow() ?? panic("Could not borrow capability from public collection")

    return capa.getBlogById(id: id, address: address, message: message, signature: signature, keyIndex: keyIndex)
}

`;
export const isSubscribed = `
import BlogManager from 0xBlogger


pub fun main(reader: Address): Bool {
    let account = getAccount(0xBlogger)
    let collection = account.getCapability(BlogManager.BlogCollectionPublicPath).borrow<&BlogManager.BlogCollection>() ?? panic("Could not borrow capability");

    return collection.isSubscribed(address: reader);

}
`;
export const getOwnersInfo = `
import BlogManager from 0xBlogger

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

`;
export const getAllBlogs = `
import BlogManager from 0xBlogger

pub fun main(): [{String: String}]
{
    return BlogManager.getBlogMetadata()
}

`;
export const getContracts = `
import BlogManager from 0xBlogger

pub fun main():{Address:UFix64}{

    var acc = getAccount(0xBlogger)
    var contracts = acc.contracts.names

    var con = acc.contracts.borrow<&BlogManager>(name: "BlogManager")!

    // log the timestamp
    log(getCurrentBlock().timestamp)
    log(getCurrentBlock().height)

    let timeDiff = 1689182500.00000000 - 2689182500.00000000
    log("timediff: ".concat(timeDiff.toString()))

    let td = UFix64(timeDiff)
    log("td: ".concat(td.toString()))

    return con.getSubscribers()

}
`;
