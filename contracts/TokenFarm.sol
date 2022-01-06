//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {

    address[] public allowedTokens;

    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokenStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public stakers;
    IERC20 public fethToken;

    constructor(address _fethTokenAddress) {
        fethToken = IERC20(_fethTokenAddress);
    }

    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }


    /// @dev Usually instead of transfering to the end user, dev usually use airdrops - users would 
    /// claim rewards themselves, which makes it a lot more gas efficient
    function issueTokens() public onlyOwner {
        for (uint256 stakersIndex=0; stakersIndex <stakers.length; stakersIndex++) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);

            fethToken.transfer(recipient, userTotalValue);

        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokenStaked[_user] >0, "No Token staked");
        for (uint256 allowedTokensIndex = 0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++) {
            totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[allowedTokensIndex]);
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token) public view returns (uint256) {
        if (uniqueTokenStaked[_user] <=0) {
            return 0;
        }
        (uint256 price, uint decimals) = getTokenValue(_token);
        return (stakingBalance[_token][_user] * price / (10**decimals));
    }

    function getTokenValue(address _token) public view returns (uint256, uint256) {
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,int price,,,) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount>0, "Amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currently no allowed");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokenStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;
        if (uniqueTokenStaked[msg.sender] ==1) {
            stakers.push(msg.sender);
        }
    }

    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokenStaked[msg.sender] = uniqueTokenStaked[msg.sender] -1;
    }

    function updateUniqueTokenStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <=0) {
            uniqueTokenStaked[_user] = uniqueTokenStaked[_user] +1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        for (uint256 allowedTokensIndex=0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }
    
}