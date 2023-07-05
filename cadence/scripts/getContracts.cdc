
pub fun main():[String]{

    var acc = getAccount(0x01cf0e2f2f715450)
    var contracts = acc.contracts.names

    log(contracts)

    return contracts

}