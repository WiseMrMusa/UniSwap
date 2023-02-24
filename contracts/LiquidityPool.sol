// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


/// @title Price Feed
/// @author Musa AbdulKareem (@WiseMrMusa)
/// @author Okoli Evans
/// @notice This gets the exchange rate of two Tokens

import { ERC20 , IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { ExchangeRate } from "./ExchangeRate.sol";


contract LiquidityPool is ExchangeRate {

    address private SWAP_ROUTER;

    mapping (bytes32 => address) private PairFactory;

    function createPair(address _tokenA, address _tokenB) internal returns (address) {
        require(_tokenA != address(0) && _tokenB != address(0));
        bytes32 pairNode = keccak256(abi.encodePacked(_tokenA,_tokenB));
        require(PairFactory[pairNode] != address(0), "Pair Factory Already Exist");
        ERC20 PairPool = new ERC20(
            string.concat(IERC20Metadata(_tokenA).name(),IERC20Metadata(_tokenB).name()),
            string.concat(IERC20Metadata(_tokenA).symbol(),IERC20Metadata(_tokenB).symbol())
            );
        PairFactory[pairNode] = address(PairPool);
        return address(PairPool);
    }

    function getPair(address _tokenA, address _tokenB) internal view returns (address) {
        require(_tokenA != address(0) && _tokenB != address(0));
        bytes32 pairNode = keccak256(abi.encodePacked(_tokenA,_tokenB));
        return PairFactory[pairNode];
    }

    function addLiquidity(
        address _tokenA, 
        address _tokenB, 
        int256 _amountInTokenA, 
        int256 _amountInTokenB
    ) external returns(bool success1, bool success2)/** WHY SUCCESS1 & SUCCESS2? */{
        address pairAddress = getPair(_tokenA,_tokenB) == address(0)? createPair(_tokenA,_tokenB) : getPair(_tokenA,_tokenB) ;
            string memory _tokenASymbol = IERC20Metadata(_tokenA).symbol();
            string memory _tokenBSymbol = IERC20Metadata(_tokenB).symbol();
            uint8 _tokenBDecimals = IERC20Metadata(_tokenB).decimals();

        int256 rateOfB = getSwapTokenPrice(
            _tokenASymbol,
            _tokenBSymbol,
            _tokenBDecimals,
            _amountInTokenA
        );

        if (_amountInTokenB >= rateOfB) {
            IERC20(_tokenA).transferFrom(
                msg.sender,
                pairAddress,
                uint256(_amountInTokenA
            ));
            IERC20(_tokenB).transferFrom(
                msg.sender,
                pairAddress,
                uint256(rateOfB));

            // (bool success1, bytes memory data1) = (_tokenA).call(abi.encodeWithSelector(0x095ea7b3,SWAP_ROUTER,_amountInTokenA));
            // (bool success2, bytes memory data2) = (_tokenB).call(abi.encodeWithSelector(0x095ea7b3,SWAP_ROUTER,rateOfB));

            require (success1 && success2, "Failed to add liquidity!");
        }
    }

        function removeLiquidity(
            address _tokenA,
            address _tokenB,
            address _to,
            uint _amount
        ) internal returns(bool success1, bool success2) {
            address pairAddress = getPair(_tokenA, _tokenB);
            //require(pairAddress, "Liquidity pool not available");
            IERC20(_tokenA).transferFrom(
                pairAddress,
                _to,
                _amount   
            );
            IERC20(_tokenB).transferFrom(
                pairAddress,
                _to,
                _amount
            );
            require(success1 && success2, "Operation failed");
    }

        function swap(
            address _tokenA,
            address _tokenB,
            int _amountToSwap,
            // address _DEXPool,
            address _buyer
        ) public returns(bool success) {
            require(_tokenA != address(0) && _tokenB != address(0), "Invalid address");
            require(uint(_amountToSwap) <= IERC20(_tokenA).balanceOf(msg.sender), "Insufficient Balance");
            string memory _tokenASymbol = IERC20Metadata(_tokenA).symbol();
            string memory _tokenBSymbol = IERC20Metadata(_tokenB).symbol();
            uint8 _tokenBDecimals = IERC20Metadata(_tokenB).decimals();
            address pairAddress = getPair(_tokenA, _tokenB);
            //require(pairAddress, "Token liquidity pool not available");
            uint amountOut = uint(getSwapTokenPrice(
                _tokenASymbol, 
                _tokenBSymbol, 
                _tokenBDecimals, 
                _amountToSwap
            ));
            require(IERC20(_tokenB).balanceOf(pairAddress) >= amountOut, "try again shortly");
            
            IERC20(_tokenA).transferFrom(
                msg.sender,
                pairAddress,
                uint(_amountToSwap)
            );
            IERC20(_tokenB).transferFrom(
                pairAddress,
                _buyer,
                amountOut
            );

            success = true;
            require(success, "Swap fail!");
        }

    // TOKENS TO SWAP, EXCHANGE RATE, ADDRESS TO RECEIVE INCOMING TOKEN, ADDRESS TO TAKE 
    // OUTGOING TOKEN, 
    //

}
