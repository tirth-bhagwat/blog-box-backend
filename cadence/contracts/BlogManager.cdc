pub contract BlogManager {

    pub let BlogStoragePath : StoragePath
    pub let BlogPublicPath : PublicPath
    pub let MinterStoragePath: StoragePath
    pub var idCount:UInt32

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
        access(contract) let subscribers: {Address: Bool}

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

        destroy () {
            destroy self.ownedBlogs
        }

    }

    pub fun createEmptyCollection(): @BlogCollection{
        return <- create BlogCollection()
    }

    pub fun createBlog(id:UInt32, title: String, description: String, body: String, author: String, type: String){
        self.idCount = self.idCount + 1
        let newBlog <- create Blog(id:self.idCount,title:title,description:description,body:body,author:author,type:type);

        let collection = self.account.borrow<&BlogCollection>(from: self.BlogStoragePath);
        
        collection!.add(blog:<-newBlog,id:self.idCount);
    }

    pub fun getBlog(id:UInt32):{String:String}{
        let collection = self.account.borrow<&BlogCollection>(from: self.BlogStoragePath);
        return collection!.getBlog(id:id);
    }


    init() {
        self.BlogStoragePath = /storage/BlogCollection
        self.BlogPublicPath = /public/BlogCollection
        self.MinterStoragePath = /storage/nftTutorialMinter

        self.idCount = 0

        self.account.save(<-self.createEmptyCollection(), to: self.BlogStoragePath)
        self.account.link<&BlogCollection>(self.BlogPublicPath, target :self.BlogStoragePath)

        self.createBlog(id:self.idCount,title:"First Blog",description:"First Blog",body:"First Blog",author:"XYZ",type:"PUBLIC")
        self.createBlog(id:self.idCount,title:"First Blog",description:"First Blog",body:"First Blog",author:"XYZ",type:"PRIVATE")
        log(self.getBlog(id:1))
	}
}