import BlogManager from 0xe03daebed8ca0615

pub fun main(): [{String: String}]
{
    return BlogManager.getBlogMetadata()
}
