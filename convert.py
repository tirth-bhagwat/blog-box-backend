#!/usr/bin/python3

import os
import sys

CADENCE_PATH = "./cadence"
CADENCE_SUB_PATHS = ["contracts", "transactions", "scripts"]
JS_PATH = "./js"
TARGET_FILE_EMULATOR = "cadence_code_emulator.js"
TARGET_FILE_TESTNET = "cadence_code_testnet.js"
PROD = False


def write_BlogManager(text, testnet=False):
    contractPath = f"{CADENCE_PATH}/contracts/BlogManager.cdc"

    with open(contractPath, "r") as f:
        contractText = f.read()

    if testnet:
        contractText = contractText.replace("0x0ae53cb6e3f42a79", "0x7e60df042a9c0868")
        contractText = contractText.replace("0xee82856bf20e2aa6", "0x9a0766d93b6608b7")

    newtext = text.replace("<<--BlogManagerHex-->>", contractText.encode("utf-8").hex())

    if testnet:
        to_replace = "0xf8d6e0586b0a20c7".encode("utf-8").hex()
        newtext = newtext.replace(
            to_replace,
            "{_____<<--Add__SubscriptionsManager__Account's__Hex__Here-->>_____}",
        )

    return newtext


convertions = {
    "0x0ae53cb6e3f42a79": "0xFlowToken",  # emulator
    "0x7e60df042a9c0868": "0xFlowToken",  # testnet
    "0xee82856bf20e2aa6": "0xFungibleToken",  # emulator
    "0x9a0766d93b6608b7": "0xFungibleToken",  # testnet
    "0xe03daebed8ca0615": "0xBlogger",
}

args = sys.argv
if len(args) > 1:
    if args[1] == "prod" or args[1] == "p":
        PROD = True

# create JS_PATH if not exists
if not os.path.exists(JS_PATH):
    os.makedirs(JS_PATH)

with open(f"{JS_PATH}/{TARGET_FILE_EMULATOR}", "w") as f:
    f.write("")

with open(f"{JS_PATH}/{TARGET_FILE_TESTNET}", "w") as f:
    f.write("")


# convert cadence to js
for sub_path in CADENCE_SUB_PATHS:
    for file in os.listdir(f"{CADENCE_PATH}/{sub_path}"):
        if file.endswith(".cdc"):
            newtext = f"export const {file[:-4]} = `\n"
            with open(f"{CADENCE_PATH}/{sub_path}/{file}", "r") as f:
                for line in f.readlines():
                    formatted = line.replace("`", "\`")
                    newtext += formatted

            if file.startswith("_"):
                if PROD:
                    continue
                file = file[1:]

            newtext += "\n`;\n"

            for key in convertions.keys():
                newtext = newtext.replace(key, convertions[key])

            with open(f"{JS_PATH}/{TARGET_FILE_EMULATOR}", "a") as f:
                if file == "DeployContract.cdc":
                    newtext = write_BlogManager(newtext, testnet=False)

                f.write(newtext)

            with open(f"{JS_PATH}/{TARGET_FILE_TESTNET}", "a") as f:
                if file == "DeployContract.cdc":
                    newtext = write_BlogManager(newtext, testnet=True)

                f.write(newtext)


print("Done!")
