// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/AttentionEscrow.sol";  // Ensure the correct path to the contract

contract DeployAttentionEscrow is Script {
    function run() external {
        // Replace with the verifier's address (could be your own or some other address)
        address verifier = vm.envAddress("ADD");

        // Start broadcasting transactions using your private key
        vm.startBroadcast();

        // Deploy the AttentionEscrow contract with the verifier address
        AttentionEscrow escrow = new AttentionEscrow(verifier);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log the address of the deployed contract
        console.log("AttentionEscrow contract deployed at:", address(escrow));
    }
}