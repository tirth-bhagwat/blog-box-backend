pub contract BlogManager {

    pub let BlogStoragePath : StoragePath
    pub let BlogPublicPath : PublicPath
    pub let MinterStoragePath: StoragePath
    pub let idCount:UInt64

    pub enum BlogType: UInt8 {
        pub case PUBLIC
        pub case PRIVATE
    }

    pub resource Blog {
        pub let id: UInt32
        pub let title: String
        pub let description: String
        access(contract) let body: String
        pub let author: Address
        pub let type: BlogType

        init(id:UInt32, title: String, description: String, body: String, author: Address, type: BlogType) {
            self.id = id
            self.title = title
            self.description = description
            self.body = body
            self.author = author
            self.type = type
        }
    }

    pub resource BlogCollection {
        pub let ownedBlogs: @{UInt32: Blog}

        init() {
            self.ownedBlogs <- {}
        }

        destroy () {
            destroy self.ownedBlogs
        }

        // pub fun getBlog(id: UInt32): &Blog {

            if self.ownedBlogs.containsKey(id){
                return  &self.ownedBlogs[id] as &Blog?
            } else {
                return panic("Blog does not exist")
            }

        // }

    }

    pub fun setup(): @BlogDict {
        return <- create BlogDict()
    }

    pub fun generateBlog(title: String, description: String, body: String, author: Address, type: BlogType): UInt32 {

        return 0


    }

    pub fun createEmptyCollection(): @BlogCollection{
        return <- create BlogCollection()
    }
    init() {
        self.BlogStoragePath = /storage/nftTutorialCollection
        self.BlogPublicPath = /public/nftTutorialCollection
        self.MinterStoragePath = /storage/nftTutorialMinter

        self.idCount = 1

        self.account.save(<-self.createEmptyCollection(), to: self.BlogStoragePath)
	}
}