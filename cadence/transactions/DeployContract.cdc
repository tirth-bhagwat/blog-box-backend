import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868

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
    }
}