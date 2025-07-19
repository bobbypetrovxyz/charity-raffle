// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CharityRaffle} from "../src/CharityRaffle.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployScript is Script {
    function run() public {
        vm.startBroadcast();

        address owner = vm.envAddress("OWNER_ADDRESS");

        address proxy = Upgrades.deployTransparentProxy(
            "CharityRaffle.sol",
            owner,
            abi.encodeCall(
                CharityRaffle.initialize,
                (
                    owner,
                    0xf9681Cb4b3Fd6ea3512BAfADCDcb25be41affc7a,
                    48792478976900488696491814297527784811430355562619149588575060881184839591775,
                    0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                    0x7e882f5cd23d22f0255cace777154e283a6e40c852912ff3765e6bb3312f8cdc
                )
            )
        );

        address implementation = Upgrades.getImplementationAddress(proxy);
        console.log("Proxy deployed at:", proxy);
        console.log("Implementation address:", implementation);

        vm.stopBroadcast();
    }
}

// forge script script/deploy.s.sol:DeployScript --broadcast --verify -vvvv --rpc-url sepolia --private-key "${PRIVATE_KEY}" --etherscan-api-key "${ETHERSCAN_API_KEY}"
// forge verify-contract 0x698c300C435a6827dA6465c62424abDB854cFFf4  ./src/CharityRaffle.sol:CharityRaffle --chain-id 11155111 --api-key ZSMG235NY762RBAICZVARPXI9C3GQED9860x698c300C435a6827dA6465c62424abDB854cFFf4
