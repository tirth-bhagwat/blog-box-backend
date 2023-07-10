import BlogManager from 0xf669cb8d41ce0c74

pub fun main():{Address:Bool}{

    var acc = getAccount(0xf669cb8d41ce0c74)
    var contracts = acc.contracts.names

    var con = acc.contracts.borrow<&BlogManager>(name: "BlogManager")!

    return con.getSubscribers()

}