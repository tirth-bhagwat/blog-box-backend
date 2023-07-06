import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

pub contract BlogManager {

    pub let BlogStoragePath : StoragePath
    pub let BlogPublicPath : PublicPath
    pub let FlowTokenVaultPath: PublicPath
    pub var idCount:UInt32
    access(contract) var subscriptionCost: UFix64

    pub resource Blog {
        pub let id: UInt32
        pub let title: String
        pub let description: String
        access(contract) let body: String
        pub let author: String
        pub let type: String

        init(id:UInt32, title: String, description: String, body: String, author: String, type: String) {
            self.id = id
            self.title = title
            self.description = description
            self.body = body
            self.author = author
            self.type = type
        }

        pub fun getData(): {String:String} {
            return {
                "id": self.id.toString(),
                "title": self.title,
                "description": self.description,
                "body": self.body,
                "author": self.author
            }
        }
    }

    pub resource BlogCollection {
        pub let ownedBlogs: @{UInt32: Blog}
        pub var subscribers: {Address: Bool}

        init() {
            self.ownedBlogs <- {}
            self.subscribers = {}
        }

        pub fun add(blog:@Blog,id:UInt32){
            self.ownedBlogs[id]<-!blog;
        }

        pub fun getBlog(id:UInt32):{String:String}{
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
        return <- create BlogCollection()
    }

    access(contract) fun addSubscriber(address: Address){
        // get the public capability
        let publicCapability = self.account.getCapability<&BlogCollection>(self.BlogPublicPath)!.borrow() ?? panic("Could not borrow capability");

        // borrow the collection
        publicCapability.addSubscriber(address: address)
    }

    access(contract) fun removeSubscriber(address: Address){
        // get the public capability
        let publicCapability = self.account.getCapability<&BlogCollection>(self.BlogPublicPath)!.borrow() ?? panic("Could not borrow capability");

        // borrow the collection
        publicCapability.removeSubscriber(address: address)
    }

    pub fun createBlog(id:UInt32, title: String, description: String, body: String, author: String, type: String){
        self.idCount = self.idCount + 1
        let newBlog: @BlogManager.Blog <- create Blog(id:self.idCount,title:title,description:description,body:body,author:author,type:type);

        let collection: &BlogManager.BlogCollection? = self.account.borrow<&BlogCollection>(from: self.BlogStoragePath);
        
        collection!.add(blog:<-newBlog,id:self.idCount);
    }

    pub fun getBlog(id:UInt32):{String:String}{

        let collection = self.account.borrow<&BlogCollection>(from: self.BlogStoragePath);
        return collection!.getBlog(id:id);

    }

    pub fun subscribe(address: Address, vault: @FungibleToken.Vault): Bool {
        if vault.balance != self.subscriptionCost {
            panic("Incorrect amount sent")
        }

        // if address is already subscribed
        if self.isSubscribed(address: address) {
            panic("Already subscribed")
        }

        let depositCapability = self.account.getCapability<&{FungibleToken.Receiver}>(self.FlowTokenVaultPath)!.borrow() ?? panic("Could not borrow capability")

        depositCapability.deposit(from: <- vault)

        self.addSubscriber(address: address)

        return true
    }

    // TODO: Improve security of this function or remove it later
    // Created now just for testing
    pub fun unsubscribe(address: Address): Bool {
        if !self.isSubscribed(address: address) {
            panic("Not subscribed")
        }

        self.removeSubscriber(address: address)

        return true
    }

    pub fun getSubscribers():{Address: Bool}{
        let collection = self.account.borrow<&BlogCollection>(from: self.BlogStoragePath);
        return collection!.getSubscribers();
    }

    pub fun isSubscribed(address: Address): Bool{
        let collection = self.account.borrow<&BlogCollection>(from: self.BlogStoragePath) ?? panic("Could not borrow capability");
        return collection.getSubscribers()[address] ?? false
    }

    init() {
        self.BlogStoragePath = /storage/BlogCollection
        self.BlogPublicPath = /public/BlogCollection
        self.FlowTokenVaultPath = /public/flowTokenReceiver

        self.idCount = 0
        self.subscriptionCost = 22.0

        self.account.save(<-self.createEmptyCollection(), to: self.BlogStoragePath)
        self.account.link<&BlogCollection>(self.BlogPublicPath, target :self.BlogStoragePath)

	}
}