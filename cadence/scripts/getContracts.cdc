
pub fun main(
    a:String, b:Int
):[String]{

    var acc = getAccount(0xdeed7593ab647e01)
    var contracts = acc.contracts.names

    log(contracts)
    log(a)
    log(b)

    return contracts

}