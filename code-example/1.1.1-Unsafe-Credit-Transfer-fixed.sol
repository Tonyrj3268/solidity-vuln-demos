// 修正後的程式碼：改正 Unsafe Credit Transfer 漏洞，先更新狀態再執行轉帳，避免重入攻擊

contract WalletFixed {
    mapping(address => uint) private userBalances;

    // 使用 'deposit' 函式存入 ETH
    function deposit() public payable {
        userBalances[msg.sender] += msg.value;
    }

    // 修正後的 withdrawBalance：先更新餘額，再進行轉帳，防止重入攻擊
    function withdrawBalance() public {
        uint amountToWithdraw = userBalances[msg.sender];
        if (amountToWithdraw > 0) {
            // 修正重點：先將用戶餘額設為 0，再執行轉帳，這樣即便攻擊合約重入，也無法重複提領
            userBalances[msg.sender] = 0;
            (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
            require(success, "Transfer failed");
        }
    }

    // 其他相關函式，例如查詢合約餘額
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}


/*
補充說明：
1. 這裡示範的漏洞即出現於進行 Credit Transfer 時，未先更新狀態，導致攻擊合約透過 fallback() 重入呼叫 withdrawBalance()。
2. 攻擊合約可利用此漏洞在一次提款操作中多次呼叫 withdrawBalance，轉移更多資金。
3. 修正方案透過先將用戶餘額歸零，再進行轉帳，從根本上避免了重入攻擊的風險。
*/
