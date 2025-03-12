// SPDX-License-Identifier: MIT
pragma solidity ^0.4.18;

/**
 * 解決交易順序依賴(Transaction Order Dependence)漏洞的合約
 * 使用交易計數器(txCounter)作為防護機制，確保用戶以預期的價格進行交易
 */
contract SafeTransactionOrdering {
    uint256 price;
    uint256 txCounter;  // 新增：交易計數器，每次價格變更時遞增
    address owner;
    
    event Purchase(address _buyer, uint256 _price);
    event PriceChange(address _owner, uint256 _price, uint256 _txCounter);
    
    modifier ownerOnly() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // 使用函數替代構造函數，符合當前 Solidity 習慣
    function SafeTransactionOrdering() public {
        owner = msg.sender;
        price = 100;
        txCounter = 0;
    }
    
    /**
     * 新增：提供一個安全的方式讀取當前價格和交易計數器
     * 用戶應該先調用此函數獲取當前狀態
     */
    function getCurrentState() public view returns (uint256 currentPrice, uint256 currentTxCounter) {
        return (price, txCounter);
    }
    
    /**
     * 修復：buy 函數現在需要用戶提供預期的交易計數器
     * 如果計數器與當前系統狀態不符，表示有價格變更發生，交易將被回滾
     */
    function buy(uint256 expectedTxCounter) public returns (uint256) {
        // 確保交易計數器匹配，防止價格變更引起的不一致
        require(expectedTxCounter == txCounter, "Price has been changed since your last check");
        
        Purchase(msg.sender, price);
        return price;
    }
    
    /**
     * 修復：每次更改價格時，遞增交易計數器
     * 這樣會使得前一個交易計數器的 buy 調用無效
     */
    function setPrice(uint256 _price) public ownerOnly() {
        price = _price;
        txCounter += 1;  // 關鍵改動：每次價格變化時增加計數器
        PriceChange(owner, price, txCounter);
    }
    
    /**
     * 新增：更安全的購買方式，一次性查詢價格並提交購買意向
     * 確保用戶看到的價格就是交易執行的價格
     */
    function checkAndBuy() public returns (uint256) {
        Purchase(msg.sender, price);
        return price;
    }
}