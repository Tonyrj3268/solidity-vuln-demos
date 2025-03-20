// 以下為修正後的程式碼，可以防範 reentrancy 攻擊，此修正版遵循 Checks-Effects-Interactions 模式

contract WalletFixed {
    // 狀態變數：儲存每個使用者的餘額
    mapping(address => uint) private userBalances;

    // 使用者可先存款，方便後續提款
    function deposit() public payable {
        userBalances[msg.sender] += msg.value;
    }

    // 安全的 withdrawBalance 函式：先更新狀態變數，再執行外部呼叫
    function withdrawBalance() public {
        uint amountToWithdraw = userBalances[msg.sender];
        require(amountToWithdraw > 0, 'No funds available');

        // 先將狀態更新，此動作防止重入攻擊
        userBalances[msg.sender] = 0;

        // 再執行外部呼叫，傳輸正確的提款金額
        (bool success, ) = msg.sender.call{value: amountToWithdraw}('');
        require(success, 'Transfer failed');
    }
}

// 補充說明：
// 1. 在修正後的 withdrawBalance 函式中，我們將 userBalances[msg.sender] = 0; 移到外部呼叫之前，斷絕了攻擊者利用回呼函式進行 reentrancy 的可能。
// 2. 此外，建議在實作中也可以參考 OpenZeppelin 的 ReentrancyGuard，以防止類似攻擊。