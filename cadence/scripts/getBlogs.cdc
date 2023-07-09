// import FlowToken from 0x0ae53cb6e3f42a79
// import FungibleToken from 0xee82856bf20e2aa6

import BlogManager from 0xe03daebed8ca0615
pub fun main( address: Address, message: String, signature: String, keyIndex: Int ): [{String: String}]? {

    return BlogManager.getAllBlogs(address: address, message: message, signature: signature, keyIndex: keyIndex)

}