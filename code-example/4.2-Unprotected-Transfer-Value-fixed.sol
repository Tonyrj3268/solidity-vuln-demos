/*
修正後程式碼說明：
在 MultiOwnable 合約中，對 newOwner 函式加入 onlyOwner 修飾符避免未經授權的人新增 owner。
這樣只有已有權限的 owner 才能新增新的 owner，避免攻擊者利用此漏洞進行未授權的操作。
*/

contract MultiOwnable {
    mapping(address => address) public owners;
    
    modifier onlyOwner() {
        require(owners[msg.sender] != address(0), "Only owner can call");
        _;
    }
    
    // 修正：加入 onlyOwner 修飾符, 僅允許現有的 owner 呼叫，避免安全性漏洞
    function newOwner(address _owner) external onlyOwner returns (bool) {
        require(_owner != address(0), "Invalid address");
        owners[_owner] = msg.sender;
        return true;
    }
}

contract TestContract is MultiOwnable {
    function withdrawAll() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
    
    function() external payable {}
}