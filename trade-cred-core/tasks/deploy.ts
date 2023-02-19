import { task, types } from "hardhat/config"

task("deploy", "Deploy a Greeter contract")
    .addOptionalParam("semaphore", "Semaphore contract address", undefined, types.string)
    .addOptionalParam("group", "Group id", "42", types.string)
    .addOptionalParam("logs", "Print the logs", true, types.boolean)
    .setAction(async ({ logs, semaphore: semaphoreAddress, group: groupId }, { ethers, run }) => {
        if (!semaphoreAddress) {
            const { semaphore } = await run("deploy:semaphore", {
                logs
            })

            semaphoreAddress = semaphore.address
        }

        const TradeCred = await ethers.getContractFactory("TradeCred")

        const tradeCred = await TradeCred.deploy(semaphoreAddress, "0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E")

        await tradeCred.deployed()

        if (logs) {
            console.info(`Trade Cred contract has been deployed to: ${tradeCred.address}`)
        }

        return tradeCred
    })