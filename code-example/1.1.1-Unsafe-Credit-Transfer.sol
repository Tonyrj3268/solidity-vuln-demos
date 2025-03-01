pragma solidity ^0.4.24;

contract Wallet {
    // 儲存每個使用者的餘額
    mapping(address => uint) private userBalances;

    //===============================================
    // 漏洞版本：Unsafe Credit Transfer (重入攻擊)
    //===============================================
    // 描述：
    // 此函式存在的問題在於先進行信用轉移（透過 call 轉帳），
    // 而在轉帳成功後才更新使用者餘額 (userBalances[msg.sender] = 0;)。
    // 如果 msg.sender 為一個惡意合約，其 fallback function 可在
    // call 執行期間再次呼叫 withdrawBalanceVulnerable()，
    // 因為使用者餘額尚未更新，將會重複取得轉帳金額，進而造成多次提款，
    // 並最終提領超過其實際擁有的餘額，這正是 DAO 攻擊利用的漏洞。
    function withdrawBalanceVulnerable() public {
        uint amountToWithdraw = userBalances[msg.sender];
        if (amountToWithdraw > 0) {
            // 【漏洞段落】：先進行轉帳，再更新餘額
            // 攻擊者可利用 call 觸發 fallback 中的重入呼叫，在餘額更新前再次提款
            msg.sender.call.value(amountToWithdraw)();
            
            // 【漏洞段落】：餘額更新在轉帳之後，無法防止重入攻擊
            userBalances[msg.sender] = 0;
        }
    }

    //===============================================
    // 安全版本：修正後的 withdrawBalance
    //===============================================
    // 修正重點：
    // 依循 Checks-Effects-Interactions 原則，
    // 先檢查條件、更新內部狀態，再進行外部互動（例如轉帳）。
    // 因此，先將使用者餘額設為 0，再進行轉帳，
    // 即使發生重入攻擊，也無法重複提款。
    function withdrawBalanceSafe() public {
        uint amountToWithdraw = userBalances[msg.sender];
        if (amountToWithdraw > 0) {
            // 【修正段落】：先更新餘額，確保重入呼叫時餘額已被清零
            userBalances[msg.sender] = 0;
            
            // 【修正段落】：再進行轉帳
            // 注意：這裡仍使用 call 轉帳，但更建議使用 transfer 或 send 限制 gas，降低其他風險
            msg.sender.call.value(amountToWithdraw)();
        }
    }

    //===============================================
    // 其他相關程式碼
    //===============================================
    // 用於存款，增加使用者餘額
    function deposit() public payable {
        userBalances[msg.sender] += msg.value;
    }
    
    // 此合約內其他功能...
}
