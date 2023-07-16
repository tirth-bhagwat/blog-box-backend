import SubscriptionsManager from 0xf8d6e0586b0a20c7

transaction {

    prepare(signer: AuthAccount) {
        log(signer.storagePaths.contains(SubscriptionsManager.SubscriptionsStoragePath))
    }

}