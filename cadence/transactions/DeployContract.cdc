import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

transaction {
    prepare(acct: AuthAccount) {
        let signer = acct
        // get the list of existing contracts
        var existingContracts = signer.contracts.names
        let BlogManager = "<<--BlogManagerHex-->>".decodeHex()
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