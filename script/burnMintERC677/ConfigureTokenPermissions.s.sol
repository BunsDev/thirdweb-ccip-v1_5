// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {BurnMintTokenPool} from "@chainlink/contracts-ccip/src/v0.8/ccip/pools/BurnMintTokenPool.sol";
import {IBurnMintERC20} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";
import {RegistryModuleOwnerCustom} from "@chainlink/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "@chainlink/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {BurnMintERC677} from "../../src/BurnMintERC677.sol";

contract DeployTokenAndPoolScript is Script {
    RegistryModuleOwnerCustom registryModuleOwnerCustom;
    TokenAdminRegistry tokenAdminRegistry;
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    Register.NetworkDetails networkDetails;

    function setUp() public {
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        networkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );

        registryModuleOwnerCustom = RegistryModuleOwnerCustom(
            networkDetails.registryModuleOwnerCustomAddress
        );
        tokenAdminRegistry = TokenAdminRegistry(
            networkDetails.tokenAdminRegistryAddress
        );
    }

    function run(address tokenAddress, address poolAddress) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        BurnMintERC677 myToken = BurnMintERC677(address(tokenAddress));

        // Step 3) Grant Mint and Burn roles to BurnMintTokenPool
        myToken.grantMintAndBurnRoles(poolAddress);

        // Step 4) Claim Admin role
        registryModuleOwnerCustom.registerAdminViaOwner(address(myToken));

        // // Step 5) Accept Admin role
        tokenAdminRegistry.acceptAdminRole(address(myToken));

        // // Step 6) Link token to pool
        tokenAdminRegistry.setPool(address(myToken), poolAddress);

        vm.stopBroadcast();
    }
}
