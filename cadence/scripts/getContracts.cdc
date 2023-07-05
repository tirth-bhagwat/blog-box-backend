
pub fun main(
    a:String, b:Int
):[String]{

    var acc = getAccount(0x8eb8bf6984a6ce20)
    var contracts = acc.contracts.names

    log(contracts)
    log(a)
    log(b)

    return contracts

}