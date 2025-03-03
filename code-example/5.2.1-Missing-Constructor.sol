// -------------------------------
// 漏洞版本
// -------------------------------
contract MissingVulnerable {
    // 狀態變數：用來儲存合約擁有者
    address private owner;

    // 限制只有擁有者能執行的修飾子
    modifier onlyowner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    // 漏洞所在：缺少建構子
    // 如果沒有建構子來初始化 owner，
    // 則 owner 變數將預設為 0x0，
    // 可能導致權限檢查失效或被惡意利用。
    
    // fallback 函式，允許合約接收 Ether
    function () external payable {}

    // 提款函式：允許 owner 提走合約所有餘額
    // 【漏洞段落】：由於 owner 未初始化，
    // 任何呼叫 withdraw() 的人可能都無法通過 onlyowner 檢查，
    // 或在部分情況下 owner 可能被誤設為不正確的地址。
    function withdraw() external onlyowner {
        owner.transfer(address(this).balance);
    }
}

// -------------------------------
// 修正版本
// -------------------------------
contract MissingFixed {
    // 狀態變數：用來儲存合約擁有者
    address private owner;

    // 限制只有擁有者能執行的修飾子
    modifier onlyowner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    // 【修正段落】：使用 constructor 函式初始化 owner，
    // 保證部署合約時即正確設定擁有者，避免手動設定造成疏漏。
    constructor() public {
        owner = msg.sender;
    }

    // fallback 函式，允許合約接收 Ether
    function () external payable {}

    // 提款函式：允許 owner 提走合約所有餘額
    function withdraw() external onlyowner {
        owner.transfer(address(this).balance);
    }
}
