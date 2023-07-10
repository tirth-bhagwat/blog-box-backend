import BlogManager from 0xe03daebed8ca0615

pub fun main():{Address:Bool}{

    var acc = getAccount(0xe03daebed8ca0615)
    var contracts = acc.contracts.names

    var con = acc.contracts.borrow<&BlogManager>(name: "BlogManager")!

    return con.getSubscribers()

}