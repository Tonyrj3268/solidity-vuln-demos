contract CallsInLoop {
    // 使用映射來追蹤每個地址應該收到的金額
    mapping(address => uint) public credits;
    // 保留原始的地址陣列，用於遍歷
    address[] public destinations;
    
    constructor(address[] memory newDestinations) {
        destinations = newDestinations;
    }
    
    // 修改後的函數使用拉取模式（Pull Pattern）
    function bad() external {
        // 將轉賬操作拆分為兩部分：
        // 1. 記錄每個地址應得的金額（此處進行）
        // 2. 讓用戶自行提取資金（在 withdrawCredits 函數中）
        for (uint i = 0; i < destinations.length; i++) {
            // 只更新狀態變數，不進行外部呼叫，大幅減少了 gas 消耗
            allowForPull(destinations[i], i);
        }
        // 即使 destinations 陣列很大，這個函數也不太可能失敗或耗盡 gas
    }
    
    // 私有函數用於記錄應得的金額
    function allowForPull(address receiver, uint amount) private {
        credits[receiver] += amount;
    }
    
    // 使用者可以呼叫此函數來提取屬於自己的資金
    // 這將風險和責任轉移給接收者，也分散了 gas 消耗
    function withdrawCredits() public {
        uint amount = credits[msg.sender];
        // 確保用戶有資金可以提取
        require(amount != 0, "No credits available to withdraw");
        // 確保合約有足夠的餘額
        require(address(this).balance >= amount, "Contract has insufficient balance");
        
        // 重要：先將用戶的餘額設為0，再進行轉賬，避免重入攻擊
        credits[msg.sender] = 0;
        
        // 進行轉賬，如果失敗，整個交易都會回滾，包括上面的餘額歸零操作
        payable(msg.sender).transfer(amount);
    }
    
    // 可選：添加分批處理功能，以處理特別大的陣列
    function processBatch(uint startIndex, uint batchSize) external {
        uint endIndex = startIndex + batchSize;
        if (endIndex > destinations.length) {
            endIndex = destinations.length;
        }
        
        for (uint i = startIndex; i < endIndex; i++) {
            allowForPull(destinations[i], i);
        }
    }
    
    // 接收資金的函數
    receive() external payable {}
}

/*
修復說明：

1. 拉取模式（Pull Pattern）：
   - 將「推送資金」改為「記錄債務，允許拉取」
   - 使用者需主動調用 withdrawCredits() 來提取資金
   - 每筆提款都是獨立的交易，一筆失敗不會影響其他交易

2. 降低 gas 消耗：
   - 迴圈中只更新狀態變數，不執行外部呼叫
   - 即使陣列很大，也能在合理的 gas 限制內完成

3. 彈性增強：
   - 增加了 processBatch 函數，允許分批處理大量地址
   - 即使地址數量超過單個區塊的處理能力，也可以分多次處理

4. 安全性提升：
   - 在進行 transfer 前先更新狀態，防止重入攻擊
   - 添加了餘額檢查，確保合約有足夠的資金進行轉賬

5. 額外功能：
   - 添加了 receive 函數，使合約能夠接收資金
   - 用戶可以隨時查看自己的可提取餘額

這種修復方法不僅解決了「迴圈中的異常處理」問題，也體現了區塊鏈開發中的最佳實踐 - 儘量將責任轉移給用戶（拉取模式），而不是合約主動推送資金。
*/