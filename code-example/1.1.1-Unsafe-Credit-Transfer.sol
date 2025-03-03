contract Wallet {
    // 儲存每個使用者的餘額
    mapping(address => uint) private userBalances;

    // ===============================================
    // 漏洞版本：withdrawBalanceVulnerable
    // ===============================================
    // 描述：
    // 此版本中，提款操作會先呼叫外部合約（msg.sender.call）
    // 再更新內部狀態（將使用者餘額設為 0）。
    // 由於外部呼叫可能觸發重入攻擊，攻擊者可利用其合約在呼叫中
    // 重複執行提款操作，從而提款金額可能超過其實際擁有之餘額，
    // 這正是 DAO 攻擊所利用的漏洞。
    function withdrawBalanceVulnerable() public {
        uint amountToWithdraw = userBalances[msg.sender];
        if (amountToWithdraw > 0) {
            // 【漏洞段落】：
            // 此處先呼叫外部合約進行轉帳，再更新內部餘額，
            // 攻擊者可在外部呼叫中利用重入攻擊，重複提領
            (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
            require(success, "Transfer failed.");
            
            // 【漏洞段落】：
            // 更新使用者餘額在外部呼叫之後，無法防範重入攻擊
            userBalances[msg.sender] = 0;
        }
    }

    // ===============================================
    // 修正版本：withdrawBalanceSafe
    // ===============================================
    // 修正重點：
    // 依循 Checks-Effects-Interactions 原則，必須先更新內部狀態，
    // 再進行外部呼叫。這樣，即使發生重入攻擊，也無法重複提款，
    // 因為使用者餘額已經被清零。
    function withdrawBalanceSafe() public {
        uint amountToWithdraw = userBalances[msg.sender];
        if (amountToWithdraw > 0) {
            // 【修正段落】：
            // 先將使用者餘額清零，防止重入攻擊時再次提款
            userBalances[msg.sender] = 0;
            
            // 【修正段落】：
            // 再進行外部呼叫轉帳，安全性得以提升
            (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
            require(success, "Transfer failed.");
        }
    }
    
    // 其他相關程式碼（例如存款函式）
    function deposit() public payable {
        userBalances[msg.sender] += msg.value;
    }
}
