pub fun main(address: Address, message: String, signature: String, keyIndex: Int) : Bool {

    let account = getAccount(address)
    let publicKeys = account.keys.get(keyIndex: keyIndex) ?? panic("No key with that index in account")
    let publicKey = publicKeys.publicKey

    let sign = signature.decodeHex()
    let msg = message.decodeHex()

    return publicKey.verify(
        signature: sign,
        signedData: msg,
        domainSeparationTag: "",
        hashAlgorithm: HashAlgorithm.SHA3_256
    )
    
}
