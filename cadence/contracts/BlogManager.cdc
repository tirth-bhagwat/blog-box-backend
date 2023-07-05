pub contract BlogManager {

    pub let storagePath: StoragePath;
    pub let blog_id: UInt32;

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

    pub resource BlogDict {
        pub let blogs_free: @{UInt32: Blog}
        pub let blogs_paid: @{UInt32: Blog}

        init() {
            self.blogs_free <- {}
            self.blogs_paid <- {}
        }

        destroy () {
            destroy self.blogs_free
            destroy self.blogs_paid
        }

        // pub fun getBlog(id: UInt32): &Blog {

        //     if self.blogs_pub.containsKey(id){
        //         return (&self.blogs_pub[id] as &Blog?) ?? panic("Blog does not exist")
        //     } else {
        //         return panic("Blog does not exist")
        //     }

        // }

    }

    pub fun setup(): @BlogDict {
        return <- create BlogDict()
    }

    pub fun generateBlog(title: String, description: String, body: String, author: Address, type: BlogType): UInt32 {

        return 0


    }
    init() {
        self.storagePath = /storage/BlogManager
        self.blog_id = 0
    }

}