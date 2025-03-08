// 修正後程式碼示例：
// 此合約修正了交易前置條件的漏洞，將一個交易計數器 txCounter 引入買入流程，
// 確保買入呼叫時必須帶入正確的交易順序，避免價格更新後先前的交易被錯誤執行

pragma solidity ^0.4.18;

contract SolutionTransactionOrdering {
    uint256 price;
    uint256 txCounter; // 新增交易計數器，用來記錄合約狀態更新順序
    address owner;
    event Purchase(address _buyer, uint256 _price);
    event PriceChange(address _owner, uint256 _price);

    modifier ownerOnly() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    // 取得目前價格
    function getPrice() public view returns (uint256) {
        return price;
    }

    // 取得目前交易計數
    function getTxCounter() public view returns (uint256) {
        return txCounter;
    }

    // 建構子初始化 owner、價格與交易計數器
    function SolutionTransactionOrdering() public {
        owner = msg.sender;
        price = 100;
        txCounter = 0;
    }

    // 修正的買入函式：必須帶入正確的交易順序參數
    function buy(uint256 _txCounter) public returns (uint256) {
        // 檢查傳入的交易計數必須與目前狀態一致
        require(_txCounter == txCounter, "Invalid transaction ordering");
        Purchase(msg.sender, price);
        return price;
    }

    // 僅允許 owner 更新價格，並在價格更新後增加交易計數
    function setPrice(uint256 _price) public ownerOnly {
        price = _price;
        txCounter += 1; // 更新交易計數，強制前序買入交易必須重送
        PriceChange(owner, price);
    }
}
