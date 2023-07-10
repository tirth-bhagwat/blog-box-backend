import os

CADENCE_PATH = "./cadence"
CADENCE_SUB_PATHS = ["contracts", "transactions", "scripts"]
JS_PATH = "./js"
TARGET_FILE = "cadence_code.js"

convertions = {
    "0x0ae53cb6e3f42a79": "0xFlowToken", # emulator
    "0x7e60df042a9c0868": "0xFlowToken", # testnet
    "0xee82856bf20e2aa6": "0xFungibleToken", # emulator
    "0x9a0766d93b6608b7": "0xFungibleToken", # testnet
    "0xf669cb8d41ce0c74": "0xBlogger"
}

# create JS_PATH if not exists
if not os.path.exists(JS_PATH):
    os.makedirs(JS_PATH)

with open(f"{JS_PATH}/{TARGET_FILE}", "w") as f:
    f.write("")


# convert cadence to js
for sub_path in CADENCE_SUB_PATHS:
    for file in os.listdir(f"{CADENCE_PATH}/{sub_path}"):
        if file.endswith(".cdc"):
            newtext = f"export const {file[:-4]} = `\n"
            with open(f"{CADENCE_PATH}/{sub_path}/{file}", "r") as f:
                for line in f.readlines():
                    newtext += line

            newtext += "\n`;\n"

            for key in convertions.keys():
                newtext = newtext.replace(key, convertions[key])

            if file == "DeployContract.cdc":
                contractPath = f"{CADENCE_PATH}/contracts/BlogManager.cdc"
                
                with open(contractPath, "r") as f:
                    contractText = f.read()

                contractText = contractText.replace("0x0ae53cb6e3f42a79" , "0x7e60df042a9c0868")
                contractText = contractText.replace("0xee82856bf20e2aa6", "0x9a0766d93b6608b7")
                newtext = newtext.replace("<<--BlogManagerHex-->>", contractText.encode("utf-8").hex())

            with open(f"{JS_PATH}/{TARGET_FILE}", "a") as f:
                f.write(newtext)

print("Done!")



