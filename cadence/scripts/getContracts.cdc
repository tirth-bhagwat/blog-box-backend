
pub fun main(
    a:String, b:Int
):[String]{

    var acc = getAccount(0xf8d6e0586b0a20c7)
    var contracts = acc.contracts.names

    log(contracts)
    log(a)
    log(b)

    return contracts

}