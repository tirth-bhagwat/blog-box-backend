import BlogManager from 0xf669cb8d41ce0c74

transaction{
    prepare(signer:AuthAccount){

        let blogManager <- BlogManager.setup();

        signer.save(<-blogManager, to: BlogManager.storagePath);

        log("BlogManager has been initialized");
    }
}