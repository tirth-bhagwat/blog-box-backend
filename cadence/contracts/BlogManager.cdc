pub contract BlogManager {

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
        pub let blogs: @{UInt32: Blog}

        init() {
            self.blogs <- {}
        }

        destroy () {
            destroy self.blogs
        }

        pub fun getBlog(id: UInt32): &Blog? {

            if self.blogs.containsKey(id){
                return  &self.blogs[id] as &Blog?
            } else {
                return panic("Blog does not exist")
            }

        }

    }

    
}