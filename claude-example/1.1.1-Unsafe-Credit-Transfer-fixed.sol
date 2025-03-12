// 修復後的安全錢包合約
contract SafeWallet {
    // 用於儲存每個用戶的餘額
    mapping(address => uint) private userBalances;
    
    // 允許用戶存款
    function deposit() external payable {
        // 將發送的以太幣記錄到用戶餘額中
        userBalances[msg.sender] += msg.value;
    }
    
    // 修復後的提款函數 - 遵循檢查-效果-互動模式
    function withdrawBalance() public {
        // 獲取用戶餘額
        uint amountToWithdraw = userBalances[msg.sender];
        
        // 檢查用戶餘額是否大於0
        if (amountToWithdraw > 0) {
            // 修復點1: 先更新餘額，再進行外部調用
            // 遵循"檢查-效果-互動"模式，防止重入攻擊
            userBalances[msg.sender] = 0;
            
            // 修復點2: 檢查轉賬結果，如果失敗則恢復餘額
            // 使用低級調用並處理可能的失敗情況
            (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
            
            // 若轉賬失敗，恢復用戶餘額
            if (!success) {
                userBalances[msg.sender] = amountToWithdraw;
                revert("Transfer failed");
            }
        }
    }
    
    // 增加重入保護修飾器（可選的額外安全層）
    bool private locked;
    
    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
    
    // 使用重入保護的提款函數（更安全的版本）
    function withdrawBalanceSafe() public nonReentrant {
        uint amountToWithdraw = userBalances[msg.sender];
        if (amountToWithdraw > 0) {
            userBalances[msg.sender] = 0;
            (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
            require(success, "Transfer failed");
        }
    }
    
    // 檢查用戶餘額
    function getBalance(address _user) external view returns (uint) {
        return userBalances[_user];
    }
    
    // 查看合約餘額
    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }
}

/*
修復說明：

1. 遵循檢查-效果-互動模式：
   - 先更新用戶餘額為0，然後再發送以太幣
   - 這確保即使接收方合約再次調用此函數，也會讀取已更新的餘額（為0）

2. 增加錯誤處理：
   - 檢查轉賬是否成功，如果失敗則恢復餘額並拋出異常
   - 這確保用戶不會因轉賬失敗而失去資金

3. 額外安全層（nonReentrant修飾器）：
   - 實現重入鎖定機制，防止同一個函數被重復調用
   - 雖然遵循檢查-效果-互動模式已經足以防止常見的重入攻擊，但這提供了更強的保護

4. 保留核心功能：
   - 合約的主要功能保持不變，用戶仍然可以存款和提款
   - 增加了安全檢查以防止攻擊，但不影響正常使用者的體驗
*/