import BlogManager from 0x045a1763c93006ca
// import FlowToken from 0x0ae53cb6e3f42a79
// import FungibleToken from 0xee82856bf20e2aa6

pub fun main(signer: Address, keyIndex: Int, sign:String, msg: String)
{
    // TODO add code to return blogs if user is subscribed
}

priv fun verifyUser(signer: Address, keyIndex: Int, sign:String, msg: String):Bool
{
    let acct = getAccount(signer)
    let accKey = acct.keys.get(keyIndex: keyIndex) ?? panic("Cannot find key at given index")
    let publicKey = accKey.publicKey

    let sign = sign.decodeHex()
    let msg = msg.decodeHex()

    let verified = publicKey.verify(
        signature: sign,
        signedData: msg,
        domainSeparationTag: "FLOW-V0.0-user",
        hashAlgorithm: HashAlgorithm.SHA3_256
    )

    if !verified {
        return false
    }

    

    return true
}