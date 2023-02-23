// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title Price Feed
/// @author Musa AbdulKareem (@WiseMrMusa)
/// @notice This gets the exchange rate of two Tokens

contract ExchangeRate is Ownable {

    /// @dev This maps the token address to the aggregator's address
    mapping (string => address) private aggregrator;

    function addAggregator(string calldata _tokenName, address _aggregatorAddress) external onlyOwner() {
        require(aggregrator[_tokenName] == address(0),"Aggregator Address already exist!");
        aggregrator[_tokenName] = _aggregatorAddress;
    }


    function deleteAggregator(string calldata _tokenName) external onlyOwner() {
        require(aggregrator[_tokenName] != address(0),"Aggregator Address does not exist");
        aggregrator[_tokenName] = address(0);
    }

    /// This gets the exchange rate of two tokens
    /// @param _from This is the token you're swapping from
    /// @param _to This is the token you are swapping to
    /// @param _decimals This is the decimal of the token you are swapping to
    function getDerivedPrice(
        string memory _from,
        string memory _to,
        uint8 _decimals
    ) public view returns (int256) {
        require(
            _decimals > uint8(0) && _decimals <= uint8(18),
            "Invalid _decimals"
        );
        int256 decimals = int256(10 ** uint256(_decimals));
        (, int256 fromPrice, , , ) = AggregatorV3Interface(aggregrator[_from])
            .latestRoundData();
        uint8 fromDecimals = AggregatorV3Interface(aggregrator[_from]).decimals();
        fromPrice = scalePrice(fromPrice, fromDecimals, _decimals);

        (, int256 toPrice, , , ) = AggregatorV3Interface(aggregrator[_to])
            .latestRoundData();
        uint8 toDecimals = AggregatorV3Interface(aggregrator[_to]).decimals();
        toPrice = scalePrice(toPrice, toDecimals, _decimals);

        return (fromPrice * decimals) / toPrice;
    }

    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    function getSwapTokenPrice(
        string memory _fromToken, 
        string memory _toToken,
        uint8 _decimals,
        int256 _amount
    ) public view returns (int256) {
        return _amount * getDerivedPrice(
            _fromToken,
             _toToken,
            _decimals);
    }


}
