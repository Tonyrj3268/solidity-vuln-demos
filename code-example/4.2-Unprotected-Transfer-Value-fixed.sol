/*
修正說明：
1. 為 newOwner 函數加入 onlyOwner 修飾，限制只有合法 owner 才能新增新 owner，避免未授權新增。
2. withdrawAll 依然全額轉移餘額，但僅允許 owner 呼叫。
3. 修改 fallback 函數以符合 Solidity 0.8.0 語法，使用 fallback() external payable 和 receive() external payable 來接收 ETH。
*/

contract MultiOwnable {
    mapping(address => address) public owners;

    constructor() {
        owners[msg.sender] = msg.sender;
    }

    modifier onlyOwner() {
        require(owners[msg.sender] != address(0), "Not an owner");
        _;
    }

    // 已修正：加入 onlyOwner 修飾，僅允許現有 owner 新增 owner
    function newOwner(address _owner) external onlyOwner returns (bool) {
        require(_owner != address(0), "Invalid owner address");
        owners[_owner] = msg.sender;
        return true;
    }
}

contract TestContract is MultiOwnable {
    // withdrawAll 函數僅允許 owner 呼叫，轉出合約所有餘額
    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // 修改後的 fallback 函數，符合 Solidity 0.8.0 語法
    fallback() external payable {}

    receive() external payable {}
}

/*
備註：
雖然修正後 newOwner 的權限問題，但 withdrawAll 使用全額轉移的行為仍存在資金轉移的一般風險，
在實際部署時應根據業務邏輯進行進一步審查和防護。
*/
