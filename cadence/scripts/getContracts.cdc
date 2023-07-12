import BlogManager from 0xe03daebed8ca0615

pub fun main():{Address:UFix64}{

    var acc = getAccount(0xe03daebed8ca0615)
    var contracts = acc.contracts.names

    var con = acc.contracts.borrow<&BlogManager>(name: "BlogManager")!

    // log the timestamp
    log(getCurrentBlock().timestamp)
    log(getCurrentBlock().height)

    let timeDiff = 1689182500.00000000 - 2689182500.00000000
    log("timediff: ".concat(timeDiff.toString()))

    let td = UFix64(timeDiff)
    log("td: ".concat(td.toString()))

    return con.getSubscribers()

}