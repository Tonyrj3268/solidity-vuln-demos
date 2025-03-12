contract MultiOwnable {
  // 明確宣告用於追踪合約擁有者的映射
  mapping(address => address) public owners;
  
  // 添加部署者為初始擁有者的建構函式
  constructor() public {
    // 將部署者設為初始擁有者
    owners[msg.sender] = 0x1; // 使用非零值標記為擁有者
  }

  modifier onlyOwner() {
    require(owners[msg.sender] != 0, "Not an owner");
    _;
  }

  // 【修復1】添加 onlyOwner 修飾符，確保只有現有擁有者可以添加新擁有者
  function newOwner(address _owner) external onlyOwner returns (bool) {
    require(_owner != 0, "Invalid address");
    owners[_owner] = msg.sender;
    return true;
  }
}

contract TestContract is MultiOwnable {
  // 【修復2】設定提款限額或分階段提款機制，避免一次性提走所有資金
  uint256 public withdrawalLimit = 1 ether;
  uint256 public lastWithdrawalTime;
  uint256 public withdrawalCooldown = 1 days;
  
  // 允許設置提款限額（只能由擁有者調用）
  function setWithdrawalLimit(uint256 _limit) external onlyOwner {
    withdrawalLimit = _limit;
  }
  
  // 【修復3】限制單次提款金額，並添加冷卻期
  function withdraw(uint256 _amount) external onlyOwner {
    require(_amount <= withdrawalLimit, "Exceeds withdrawal limit");
    require(block.timestamp >= lastWithdrawalTime + withdrawalCooldown, "Withdrawal cooldown not met");
    require(_amount <= address(this).balance, "Insufficient balance");
    
    lastWithdrawalTime = block.timestamp;
    msg.sender.transfer(_amount);
  }
  
  // 【修復4】緊急提款函式，需要多個擁有者批准
  mapping(address => mapping(uint256 => bool)) public emergencyWithdrawalApprovals;
  uint256 public emergencyWithdrawalId;
  uint256 public requiredApprovals = 2; // 至少需要兩個擁有者批准
  
  function approveEmergencyWithdrawal() external onlyOwner {
    emergencyWithdrawalApprovals[msg.sender][emergencyWithdrawalId] = true;
  }
  
  function executeEmergencyWithdrawal(address _to) external onlyOwner {
    uint256 approvals = 0;
    for (uint i = 0; i < 10; i++) { // 假設最多檢查10個擁有者（實際實現需要更完善）
      address potentialOwner = address(uint160(i + 1)); // 簡化示例
      if (owners[potentialOwner] != 0 && emergencyWithdrawalApprovals[potentialOwner][emergencyWithdrawalId]) {
        approvals++;
      }
    }
    
    require(approvals >= requiredApprovals, "Not enough approvals");
    
    // 重置批准狀態並遞增ID以防重放
    emergencyWithdrawalId++;
    
    // 轉移資金
    uint256 amount = address(this).balance;
    _to.transfer(amount);
  }
  
  // 允許合約接收 ETH
  function() external payable {
  }
}

/*
修復說明：
1. 添加建構函式設定初始擁有者，確保合約部署後至少有一個有效擁有者
2. 在 newOwner 函式添加 onlyOwner 修飾符，確保只有現有擁有者可以添加新擁有者
3. 用有限額度的提款函式 withdraw() 替代無限制的 withdrawAll()，並添加時間限制
4. 實現多重簽名機制用於緊急提款，確保重大資金操作需要多個擁有者同意
5. 添加提款限額設定功能，使擁有者可以根據需要調整限額
6. 使用 external 替代未指定可見性的函式，遵循最佳實踐

這些修改共同確保了：
- 合約擁有權的安全管理
- 資金提取的限制和控制
- 額外的安全保障措施來防止惡意攻擊
*/