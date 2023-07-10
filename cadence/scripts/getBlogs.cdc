import BlogManager from 0xe03daebed8ca0615

pub fun main( address: Address, message: String, signature: String, keyIndex: Int ): [{String: String}]? {

    return BlogManager.getAllBlogs(address: address, message: message, signature: signature, keyIndex: keyIndex)

}