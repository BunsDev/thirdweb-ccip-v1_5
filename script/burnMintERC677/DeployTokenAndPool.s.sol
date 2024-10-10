// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {BurnMintERC677} from "../../src/BurnMintERC677.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {BurnMintTokenPool} from "@chainlink/contracts-ccip/src/v0.8/ccip/pools/BurnMintTokenPool.sol";
import {IBurnMintERC20} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";
import {RegistryModuleOwnerCustom} from
    "@chainlink/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "@chainlink/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";

contract DeployTokenAndPoolScript is Script {
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    Register.NetworkDetails networkDetails;

    BurnMintERC677 public myToken;

    RegistryModuleOwnerCustom registryModuleOwnerCustom;
    TokenAdminRegistry tokenAdminRegistry;

    function setUp() public {
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        networkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        registryModuleOwnerCustom = RegistryModuleOwnerCustom(networkDetails.registryModuleOwnerCustomAddress);
        tokenAdminRegistry = TokenAdminRegistry(networkDetails.tokenAdminRegistryAddress);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Step 1) Deploy token
        myToken = new BurnMintERC677("My Token Burn And Mint", "MTBnM", 18, type(uint256).max);

        // Step 2) Deploy BurnMintTokenPool
        address[] memory allowlist = new address[](0);
        BurnMintTokenPool burnMintTokenPool = new BurnMintTokenPool(
            IBurnMintERC20(address(myToken)), allowlist, networkDetails.rmnProxyAddress, networkDetails.routerAddress
        );

        // Step 3) Grant Mint and Burn roles to BurnMintTokenPool
        myToken.grantMintAndBurnRoles(address(burnMintTokenPool));

        // Step 4) Claim Admin role
        registryModuleOwnerCustom.registerAdminViaOwner(address(myToken));

        // Step 5) Accept Admin role
        tokenAdminRegistry.acceptAdminRole(address(myToken));

        // Step 6) Link token to pool
        tokenAdminRegistry.setPool(address(myToken), address(burnMintTokenPool));

        vm.stopBroadcast();
    }
}
