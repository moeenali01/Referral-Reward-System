// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/ReferralToken.sol";

import {ReferralSystem} from "../src/referral.sol";

import "forge-std/Script.sol";

// import "../lib/forge-std/src/Vm.sol";

contract DeployScript is Script {
    function run() public {
        string memory name = "Referral Token";
        string memory symbol = "RFT";
        uint8 decimals = 18;
        uint256 maxSupply = 1_000_000 * 10 ** decimals;
        address admin = msg.sender;

        uint256 referralReward = 1000;
        uint256 refereeReward = 100;
        vm.startBroadcast();

        // Deploy the ERC20 token contract
        ReferralToken token = new ReferralToken(name, symbol, decimals, maxSupply, admin);

        // Log the ERC20 token address
        console.log("ReferralToken Address:", address(token));

        vm.stopBroadcast();

        vm.startBroadcast();

        // Deploy the Wallet contract and pass the ERC20 token address to the constructor
        ReferralSystem referral = new ReferralSystem(address(token), referralReward, refereeReward);

        // Log the Wallet contract address
        console.log("ReferralSystem Contract Address:", address(referral));

        vm.stopBroadcast();
    }
}
