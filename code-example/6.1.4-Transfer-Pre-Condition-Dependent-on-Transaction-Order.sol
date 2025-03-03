// -------------------------------
// 漏洞版本：TransactionOrderingVulnerable
// -------------------------------
contract TransactionOrderingVulnerable {
    // 狀態變數：價格及合約擁有者
    uint256 price;
    address owner;
    
    // 事件：記錄購買及價格變更
    event Purchase(address _buyer, uint256 _price);
    event PriceChange(address _owner, uint256 _price);
    
    // 僅限擁有者呼叫的修飾子
    modifier ownerOnly() {
        require(msg.sender == owner, "only owner can call");
        _;
    }
    
    // 建構子：於部署時初始化擁有者與價格
    function TransactionOrderingVulnerable() public {
        owner = msg.sender;
        price = 100;
    }
    
    // buy 函式：直接回傳當前價格並觸發 Purchase 事件
    // 【漏洞段落】：
    // 此函式未考慮交易執行順序的影響，
    // 若在 setPrice() 呼叫改變價格後，buy() 交易因交易順序問題先執行，
    // 則可能導致購買條件不正確或交易未按預期執行。
    function buy() public returns (uint256) {
        Purchase(msg.sender, price);
        return price;
    }
    
    // setPrice 函式：允許擁有者變更價格，並觸發 PriceChange 事件
    // 此處未對交易順序作任何處理，可能影響後續 buy() 的正確性
    function setPrice(uint256 _price) public ownerOnly {
        price = _price;
        PriceChange(owner, price);
    }
}

// -------------------------------
// 修正版本：SolutionTransactionOrdering
// -------------------------------
contract SolutionTransactionOrdering {
    // 狀態變數：價格、交易計數器（用於強制交易順序）及合約擁有者
    uint256 price;
    uint256 txCounter;
    address owner;
    
    // 事件：記錄購買及價格變更
    event Purchase(address _buyer, uint256 _price);
    event PriceChange(address _owner, uint256 _price);
    
    // 僅限擁有者呼叫的修飾子
    modifier ownerOnly() {
        require(msg.sender == owner, "only owner can call");
        _;
    }
    
    // 取得當前價格的輔助函式
    function getPrice() public view returns (uint256) {
        return price;
    }
    
    // 取得當前交易計數器的輔助函式
    function getTxCounter() public view returns (uint256) {
        return txCounter;
    }
    
    // 建構子：初始化擁有者、價格及交易計數器
    function SolutionTransactionOrdering() public {
        owner = msg.sender;
        price = 100;
        txCounter = 0;
    }
    
    // buy 函式：必須傳入正確的交易計數器值才能成功執行
    // 【修正段落】：
    // 透過要求呼叫者提供 _txCounter 與合約內部 txCounter 相符，
    // 強制交易按照預期順序執行，避免因交易排序不正確而導致購買失敗或條件錯誤。
    function buy(uint256 _txCounter) public returns (uint256) {
        require(_txCounter == txCounter, "order mismatch");
        Purchase(msg.sender, price);
        return price;
    }
    
    // setPrice 函式：變更價格時同時遞增交易計數器，作為後續買入的前置條件
    // 【修正段落】：
    // 每次變更價格後，txCounter 都會增加，迫使後續買入交易必須使用更新後的交易計數器，
    // 這樣可以確保交易執行的正確順序，降低因交易順序錯亂而導致的錯誤風險。
    function setPrice(uint256 _price) public ownerOnly {
        price = _price;
        txCounter += 1;
        PriceChange(owner, price);
    }
}
