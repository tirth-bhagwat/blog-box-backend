transaction {
    prepare(acct:AuthAccount) {
        let signer = acct
        // get the list of existing contracts
        var existingContracts = signer.contracts.names
        let BlogManager = "pub contract BlogManager {pub var greeting: String pub fun changeGreeting(newGreeting: String) {self.greeting = newGreeting}init() {self.greeting = \"Hello, World!\"}}".utf8
        // Check if the contract name already exists
        if (existingContracts.contains("BlogManager")) {
            // If it does, throw an error
            panic("Contract with name BlogManager already exists")
        }

        // Create a new contract with the name BlogManagerA
        // TODO: Add the code for the BlogManager contract from somewhere

        signer.contracts.add(name: "BlogManager", code: BlogManager)
    }

    execute {
    }
}