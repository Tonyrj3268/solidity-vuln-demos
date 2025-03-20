/*
修正版本：SolutionTransactionOrdering
修正說明：
1. 為防範交易順序攻擊，新增 txCounter 變數追蹤狀態更新次數。
2. buy() 函式必須傳入最新的 txCounter 才能成功執行，確保交易在正確的狀態下處理。
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SolutionTransactionOrdering {
    uint256 public price;
    uint256 public txCounter;
    address public owner;

    event Purchase(address indexed _buyer, uint256 _price);
    event PriceChange(address indexed _owner, uint256 _price);

    modifier ownerOnly() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    // constructor 使用最新的 Solidity 語法
    constructor() {
        owner = msg.sender;
        price = 100;
        txCounter = 0;
    }

    // 查詢當前的價格與交易計數器
    function getPrice() public view returns (uint256) {
        return price;
    }

    function getTxCounter() public view returns (uint256) {
        return txCounter;
    }

    // 修正重點：buy() 必須由外部提交正確的 txCounter 才能成功執行，此機制避免了由於 state 改變而導致交易失效
    function buy(uint256 _txCounter) public returns (uint256) {
        require(_txCounter == txCounter, "Transaction order mismatch");
        emit Purchase(msg.sender, price);
        return price;
    }

    // 當 owner 呼叫 setPrice() 更新價格時，必須同步更新 txCounter，從而確保後續的 buy() 交易都必須符合最新的狀態
    function setPrice(uint256 _price) public ownerOnly {
        price = _price;
        txCounter += 1;
        emit PriceChange(owner, price);
    }
}
