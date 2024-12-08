// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {BASE_Buster} from "../src/BSTR.sol";
import "../src/interfaces/IAmmFactory.sol";
import "../src/interfaces/IAmmRouter02.sol";

contract deploy_BSTR is Script {
    BASE_Buster public bstr;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
//BSC TESTNET
    //owner: 0xfcD9F2d36f7315d2785BA19ca920B14116EA3451
    //taxWalletSecondary: 0x000000000000000000000000000000000000dEaD
    //factory: 0x6725F303b657a9451d8BA641348b6761A6CC7a17
    //router 0xD99D1c33F9fC3444f8101754aBC46c52416550D1

//BASE MAINNET
    //owner: 0xc1532B9eC061b2d824FF079A2B5B416A847357cc
    //taxWalletSecondary: 0x24ABA1071e2D7878120CF471C4267e97687D5Ab4
    //factory: 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6
    //router 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
        bstr = new BASE_Buster(
            address(0xfcD9F2d36f7315d2785BA19ca920B14116EA3451),//address _owner,
            address(0x000000000000000000000000000000000000dEaD),//address _taxWalletSecondary,
            IAmmFactory(0x6725F303b657a9451d8BA641348b6761A6CC7a17),//IAmmFactory _factory,
            IAmmRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1)//IAmmRouter02 _router
        );

        vm.stopBroadcast();
    }
}
