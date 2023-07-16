async function signMessage() {

    let msgHex = Buffer.from("FLOW-V0.0-user").toString("hex")

    const rightPaddedHexBuffer = (value, pad) => {
        return Buffer.from(value.padEnd(pad * 2, 0), 'hex')
    }

    const signMessage = async () => {
        const USER_DOMAIN_TAG = rightPaddedHexBuffer(
            Buffer.from('FLOW-V0.0-user').toString('hex'),
            32
        ).toString('hex');
        const MSG = Buffer.from("FOO").toString("hex")
        console.log("USER_DOMAIN_TAG", USER_DOMAIN_TAG)
        console.log("MSG", MSG)
        try {
            console.log("signing message")
            console.log(USER_DOMAIN_TAG + MSG)
            //👇  will be sent to the script in the message field
            msgHex = USER_DOMAIN_TAG + MSG
            return await fcl.currentUser.signUserMessage(USER_DOMAIN_TAG + MSG)
        } catch (error) {
            console.log(error)
        }
    }


    const signature = await signMessage()

    // I have already added
    // mesHex to the signature object
    signature[0].msg = msgHex
    console.log("signature", signature)

    // sample signature object
    // {
    //     "f_type": "CompositeSignature",
    //     "f_vsn": "1.0.0",
    //     "addr": "0x2e0cdfd7165ceed3",
    //     "keyId": 1,
    //     "signature": "c2428d59af3f0fe603845da1b783df1d868bd8aff0326e36e92a8cc5e92e2988c19b46e2970532d2e11f49ecdd1d3de04fe3d348287a7bff6fd7e4a76e54a768",
    //     "msg": "464c4f572d56302e302d75736572000000000000000000000000000000000000464f4f"
    // }

}