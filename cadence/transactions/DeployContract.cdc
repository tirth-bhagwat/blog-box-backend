transaction {
    prepare(acct:AuthAccount) {
        let signer = acct
        // get the list of existing contracts
        var existingContracts = signer.contracts.names
        let BlogManager2 = "pub contract BlogManager2 {;    pub let BlogStoragePath : StoragePath;    pub let BlogPublicPath : PublicPath;    pub let MinterStoragePath: StoragePath;    pub let idCount:UInt64;    pub enum BlogType: UInt8 {;        pub case PUBLIC;        pub case PRIVATE;    };    pub resource Blog {;        pub let id: UInt32;        pub let title: String;        pub let description: String;        access(contract) let body: String;        pub let author: Address;        pub let type: BlogType;        init(id:UInt32, title: String, description: String, body: String, author: Address, type: BlogType) {;            self.id = id;            self.title = title;            self.description = description;            self.body = body;            self.author = author;            self.type = type;        };    };    pub resource BlogCollection {;        pub let ownedBlogs: @{UInt32: Blog};        init() {;            self.ownedBlogs <- {};        };        destroy () {;            destroy self.ownedBlogs;        };        pub fun getBlog(id: UInt32): &Blog? {;            if self.ownedBlogs.containsKey(id){;                return  &self.ownedBlogs[id] as &Blog?;            } else {;                return panic(\"Blog does not exist\");            };        };    };    pub fun createEmptyCollection(): @BlogCollection{        return <- create BlogCollection();    };    init() {;        self.BlogStoragePath = /storage/nftTutorialCollection2;        self.BlogPublicPath = /public/nftTutorialCollection2;        self.MinterStoragePath = /storage/nftTutorialMinter;        self.idCount = 1;        self.account.save(<-self.createEmptyCollection(), to: self.BlogStoragePath);	};}".utf8
        // Check if the contract name already exists
        if (existingContracts.contains("BlogManager2")) {
            // If it does, throw an error
            panic("Contract with name BlogManager already exists")
        }

        // Create a new contract with the name BlogManagerA
        // TODO: Add the code for the BlogManager contract from somewhere

        signer.contracts.add(name: "BlogManager2", code: BlogManager2)
    }

    execute {
    }
}