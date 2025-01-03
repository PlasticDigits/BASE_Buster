// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BSTRTaxMan} from "./BSTRTaxMan.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IAmmRouter02.sol";/*

╔══════════════════════════════════════════════════════╗
║░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║
║░░░░░░░░░░░██████╗░░█████╗░░██████╗███████╗░░░░░░░░░░░║
║░░░░░░░░░░░██╔══██╗██╔══██╗██╔════╝██╔════╝░░░░░░░░░░░║
║░░░░░░░░░░░██████╦╝███████║╚█████╗░█████╗░░░░░░░░░░░░░║
║░░░░░░░░░░░██╔══██╗██╔══██║░╚═══██╗██╔══╝░░░░░░░░░░░░░║
║░░░░░░░░░░░██████╦╝██║░░██║██████╔╝███████╗░░░░░░░░░░░║
║░░░░░░░░░░░╚═════╝░╚═╝░░╚═╝╚═════╝░╚══════╝░░░░░░░░░░░║
║░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║
║░░██████╗░██╗░░░██╗░██████╗████████╗███████╗██████╗░░░║
║░░██╔══██╗██║░░░██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗░░║
║░░██████╦╝██║░░░██║╚█████╗░░░░██║░░░█████╗░░██████╔╝░░║
║░░██╔══██╗██║░░░██║░╚═══██╗░░░██║░░░██╔══╝░░██╔══██╗░░║
║░░██████╦╝╚██████╔╝██████╔╝░░░██║░░░███████╗██║░░██║░░║
║░░╚═════╝░░╚═════╝░╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝░░║
║░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║
╚══════════════════════════════════════════════════════╝

As Presented By:
ｐｌａｓｔｉｃ ｄｉｇｉｔｓ


*/contract BASE_Buster is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    mapping(address account => bool isExempt) public isExempt;

    //Cannot be altered, only disabled. 1% max.
    uint256 maxBalance;
    uint256 buyTaxBasis = 200; // 2.00%
    uint256 sellTaxBasis = 200; // 2.00%

    BSTRTaxMan immutable bstrTaxMan;

    address immutable wethPairV2;



    error OverMax(uint256 amount, uint256 max);

    constructor(address _owner, address _taxWalletSecondary, IAmmFactory _factory, IAmmRouter02 _router)
        ERC20("BASE Buster", "BSTR")
        ERC20Permit("BASE Buster")
        Ownable(_owner)
    {
        bstrTaxMan = new BSTRTaxMan(IERC20(this),_router,_taxWalletSecondary);

        isExempt[address(bstrTaxMan)] = true;
        isExempt[address(bstrTaxMan.taxWalletSecondary())] = true;
        isExempt[owner()] = true;
        isExempt[msg.sender] = true;

        wethPairV2 = _factory.createPair(
            address(this),
            _router.WETH()
        );

        _mint(owner(),1_000_000_000 ether);
        maxBalance = totalSupply() / 100;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (
            (from != wethPairV2 && to != wethPairV2) || //not a sell or buy
            //from == address(0) || Total supply is minted in constructor.
            to == address(0) ||
            value == 0 ||
            isExempt[from] ||
            isExempt[to]
        ) {
            //Default behavior for mints, burns, exempt, transfers
            super._update(from, to, value);
        } else {
            uint256 taxRate = 0;
            if (from == wethPairV2) {
                //buy
                taxRate = buyTaxBasis;
                uint256 tax = value * taxRate / 10_000;
                super._update(from,to,value-tax);
                super._update(from,address(bstrTaxMan),tax);
            } else {
                //sell
                taxRate = sellTaxBasis;
                uint256 tax = value * taxRate / 10_000;
                super._update(from,address(bstrTaxMan),tax);
                //taxman goes first
                if(balanceOf(address(bstrTaxMan)) > totalSupply() / 10_000) {
                    bstrTaxMan.sendTaxes();

                }
                super._update(from,to,value-tax);
            }
        }

        _revertIfStandardWalletAndOverMaxHolding(from);
        _revertIfStandardWalletAndOverMaxHolding(to);
    }

    function OWNER_disableMaxWallet() onlyOwner external {
        maxBalance = type(uint256).max;
    }

    function OWNER_setTaxes(
        uint16 _buyTaxBasis,
        uint16 _sellTaxBasis
    ) external onlyOwner {
        buyTaxBasis = _buyTaxBasis;
        sellTaxBasis = _sellTaxBasis;
        if(buyTaxBasis + sellTaxBasis > 2000) {
            revert OverMax(buyTaxBasis+sellTaxBasis,2000);
        }
    }

    function OWNER_rescueTokens(IERC20 _token) onlyOwner external {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function _revertIfStandardWalletAndOverMaxHolding(
        address wallet
    ) internal view {
        if (
            wallet != wethPairV2 &&
            !isExempt[wallet] &&
            balanceOf(wallet) > maxBalance
        ) {
            revert OverMax(balanceOf(wallet), maxBalance);
        }
    }
}
