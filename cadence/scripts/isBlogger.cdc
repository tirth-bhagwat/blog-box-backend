
pub fun main(user: Address): Bool{

    let acct = getAccount(user);
    return acct.contracts.names.contains("BlogManager");
    
}