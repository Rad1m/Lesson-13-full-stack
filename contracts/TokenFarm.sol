// SPDX-License-Identifier: MIT

// GOALS FOR THIS PROJECT:
// stake Tokens - DONE
// unstake tokens - DONE
// issue tokens - DONE
// add allowed tokens - DONE
// get token value - DONE
// optional - burn tokens (DONE)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    // mapping token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;

    address[] public stakers;
    address[] public allowedTokens;
    
    // we need to know what is address of token for rewards and thats why we create constructor
    IERC20 public dappToken;
    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    // this is price feed from chainlink, only owner of the contract can define where the price comes on
    // for security resons, it is impornat to make function onlyOwner
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        // Issue tokens to all stakers
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            // send a token reward to stakers based on their TVL
            uint256 userTotalValue = getUserTVL(recipient);
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    ////////////////////////////////////////////////////////////
    ///        THIS IS MY OWN CODE FOR BURNING TOKENS        ///
    ////////////////////////////////////////////////////////////

    // burn tokens of all stakers
    function burnTokens(address _token) public onlyOwner {
        address burnAddress = 0x000000000000000000000000000000000000dEaD;
        uint256 balance = stakingBalance[_token][msg.sender]; // get staked balance of the token from the sender (user sends request)
        require(balance > 0, "Staking balance can't be 0");
        IERC20(_token).transfer(burnAddress, balance);
        stakingBalance[_token][msg.sender] = 0; // this is burning the entire balance, you can add option to choose how much to burn
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    ////////////////////////////////////////////////////////////
    ///                       FINISH                         ///
    ////////////////////////////////////////////////////////////

    function getUserTVL(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // price of the token multipllied by staking balance
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    // this function gets value of the token
    // for sport result, we will need an oracle which can provide results in a way chain link does
    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // chainlink price feed
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currently not allowed");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender]; // get staked balance of the token from the sender (user sends request)
        require(balance > 0, "Staking balance can't be 0");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0; // this is unstaking the entire balance, would be better to let user choose how much to unstake
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
        // additional functionalilty would be to remove user from the stakers array, line of code with address[] public stakers; however removing from array is consuming gas
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}
