// -------------------------------
// 漏洞版本
// -------------------------------
contract MultiOwnable {
    // 儲存擁有者的對應關係（此處假設非零地址表示擁有者）
    mapping(address => address) public owners;

    // 限制只有擁有者能呼叫的修飾子
    modifier onlyOwner() {
        require(owners[msg.sender] != address(0), "not owner");
        _;
    }

    // 設定新擁有者
    // 注意：此函式未加上 onlyOwner 限制，可能導致權限控制不足，但本漏洞重點在後續轉帳上
    function newOwner(address _owner) external returns (bool) {
        require(_owner != address(0), "invalid address");
        owners[_owner] = msg.sender;
        return true;
    }
}

contract TestContractVulnerable is MultiOwnable {
    // 可接收 Ether 的 fallback 函式
    function() external payable {}

    // 漏洞函式 withdrawAll
    // 此處直接使用 address(this).balance 取得合約所有餘額並全部轉給呼叫者
    // 【漏洞段落】：未對轉帳金額設限，若合約累積大量資金，則一次性全部轉移會增加資金濫用的風險
    function withdrawAll() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}

// -------------------------------
// 修正版本
// -------------------------------
contract TestContractFixed is MultiOwnable {
    // 可接收 Ether 的 fallback 函式
    function() external payable {}

    // 設定一個提款限制，限制單次轉帳的金額上限
    uint public withdrawalLimit;

    // 只有擁有者可設定提款限制
    function setWithdrawalLimit(uint _limit) external onlyOwner {
        // 可加入額外檢查，例如不得超過合約初始資金的某個比例
        withdrawalLimit = _limit;
    }

    // 安全的部分提款函式：僅允許轉移小於或等於提款限制的金額
    // 【修正段落】：透過傳入 _amount 並檢查其是否超過預設的提款上限，
    // 避免因為一次轉移全部餘額而造成高風險操作
    function withdrawPartial(uint _amount) external onlyOwner {
        require(_amount <= withdrawalLimit, "over withdrawal limit");
        require(address(this).balance >= _amount, "insufficient balance");
        msg.sender.transfer(_amount);
    }

    // 或提供一個 withdrawAll 版本，但僅在餘額低於提款上限時才允許全額提領
    // 【修正段落】：這樣可以避免在合約資金累積過多時一次性全額轉出
    function withdrawAll() external onlyOwner {
        require(address(this).balance <= withdrawalLimit, "over withdrawal limit");
        msg.sender.transfer(address(this).balance);
    }
}