// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IAmmRouter02.sol";
//The tax man cometh for us all

contract BSTRTaxMan is ReentrancyGuard {
    address public taxWalletSecondary = 0x24ABA1071e2D7878120CF471C4267e97687D5Ab4;
    IERC20 immutable BSTR;
    IAmmRouter02 public router =
        IAmmRouter02(0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24); //BASE v2

    modifier onlyBstrOwner() {
        if(
            msg.sender != _bstrOwner()
        ) {
            revert Ownable.OwnableInvalidOwner(msg.sender);
        }
        _;
    }

    constructor(IERC20 _bstr) {
        BSTR = _bstr;
        BSTR.approve(address(router), type(uint256).max);
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

    function _bstrOwner() private view returns (address bstrOwner_) {
        return Ownable(address(BSTR)).owner();
    }
}