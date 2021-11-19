/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./POLDibbler.sol";
import "../../../libraries/LibClaim.sol";

/**
 * @author Publius
 * @title LPField sows LP.
**/
contract LPFieldFacet is POLDibbler {

    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    function claimAndSowLP(uint256 amount, LibClaim.Claim calldata claim) external {
        LibClaim.claim(claim, false);
        _sowLP(amount);
    }

    function claimAddAndSowLP(
        uint256 lp,
        uint256 buyBeanAmount,
        uint256 buyEthAmount,
        LibMarket.AddLiquidity calldata al,
        LibClaim.Claim calldata claim
    )
        external
        payable
    {
        uint256 allocatedBeans = LibClaim.claim(claim, true);
        _addAndSowLP(lp, buyBeanAmount, buyEthAmount, allocatedBeans, al);
    }

    function sowLP(uint256 amount) public {
        pair().transferFrom(msg.sender, address(this), amount);
        _sowLP(amount);
    }

    function addAndSowLP(uint256 lp,
        uint256 buyBeanAmount,
        uint256 buyEthAmount,
        LibMarket.AddLiquidity calldata al
    )
        public
        payable
    {
        require(buyBeanAmount == 0 || buyEthAmount == 0, "Silo: Silo: Cant buy Ether and Beans.");
        _addAndSowLP(lp, buyBeanAmount, buyEthAmount, 0, al);
    }

    function _addAndSowLP(uint256 lp,
        uint256 buyBeanAmount,
        uint256 buyEthAmount,
        uint256 allocatedBeans,
        LibMarket.AddLiquidity calldata al
    )
        internal {
        uint256 boughtLP = LibMarket.swapAndAddLiquidity(buyBeanAmount, buyEthAmount, allocatedBeans, al);
        if (lp>0) pair().transferFrom(msg.sender, address(this), lp);
        _sowLP(lp.add(boughtLP));
    }

    function _sowLP(uint256 amount) internal {
        _sowPOL(amount, lpToLPBeans(amount));
    }

    /**
     * Shed
    **/

    function reserves() internal view returns (uint256, uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair().getReserves();
        return (s.index == 0 ? reserve1 : reserve0,s.index == 0 ? reserve0 : reserve1);
    }

    function lpToLPBeans(uint256 amount) internal view returns (uint256) {
        (,uint256 beanReserve) = reserves();
        return amount.mul(beanReserve).mul(2).div(pair().totalSupply());
    }

}
