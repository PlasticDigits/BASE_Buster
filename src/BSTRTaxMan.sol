// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IAmmRouter02.sol";
//The tax man cometh for us all

contract BSTRTaxMan is ReentrancyGuard {
    address public taxWalletSecondary;
    IERC20 immutable BSTR;
    IAmmRouter02 immutable router;

    modifier onlyBstrOwner() {
        if(
            msg.sender != _bstrOwner()
        ) {
            revert Ownable.OwnableInvalidOwner(msg.sender);
        }
        _;
    }

    constructor(IERC20 _bstr, IAmmRouter02 _router, address _taxWalletSecondary) {
        BSTR = _bstr;
        router = _router;
        taxWalletSecondary = _taxWalletSecondary;
    }

    function sendTaxes() external nonReentrant {
        uint256 bstrBal = BSTR.balanceOf(address(this));
        uint256 bstrBalHalf = bstrBal / 2;
        address[] memory path = new address[](2);
        path[0] = address(BSTR);
        path[1] = address(router.WETH());
        if(bstrBal > BSTR.allowance(address(this), address(router))) {
            BSTR.approve(address(router), type(uint256).max);
        }
        router.swapExactTokensForETH(bstrBalHalf, 0, path, _bstrOwner(), block.timestamp);
        router.swapExactTokensForETH(bstrBalHalf, 0, path, taxWalletSecondary, block.timestamp);
    }

    function OWNER_setTaxWalletSecondary(address _to) onlyBstrOwner external {
        taxWalletSecondary = _to;
    }

    function OWNER_rescueTokens(IERC20 _token) onlyBstrOwner external {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function _bstrOwner() private view returns (address bstrOwner_) {
        return Ownable(address(BSTR)).owner();
    }
}