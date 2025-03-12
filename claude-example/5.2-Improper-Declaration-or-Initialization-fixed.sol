// 修復後的智能合約 - 正確初始化資源

contract FixedWallet {
    // 狀態變數
    address public owner;
    bool public initialized;
    mapping(address => uint256) public balances;
    
    // 修復方案1：在構造函數中正確初始化 owner
    constructor() {
        owner = msg.sender; // 正確初始化 owner
    }
    
    // 修復方案2：如果需要保留 initialize 函式（如用於代理合約模式），確保它只能被呼叫一次
    function initialize(address _owner) public {
        require(!initialized, "Contract has already been initialized");
        require(_owner != address(0), "Invalid owner address");
        owner = _owner;
        initialized = true;
    }
    
    // 修復方案3：新增修飾器確保只有 owner 可以執行特定函式
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // 修復方案4：確保合約已初始化
    modifier isInitialized() {
        require(initialized, "Contract is not initialized");
        _;
    }
    
    // 存款函式 - 保持不變
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    // 取款函式 - 保持不變
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    // 提取所有資金的函式 - 使用適當修飾器
    function withdrawAll() public onlyOwner isInitialized {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // 修復方案5：新增函式讓 owner 可以轉移所有權
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
    
    // 接收資金的函式
    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}

/*
修復說明：
1. 在建構函數中正確初始化 owner 為部署合約的地址 (msg.sender)
2. 增強 initialize 函式，添加檢查確保它只能被呼叫一次，並且不能設置零地址為 owner
3. 新增 onlyOwner 修飾器，用於限制某些函式只能由 owner 呼叫
4. 新增 isInitialized 修飾器，確保合約在使用前已經正確初始化
5. 新增 transferOwnership 函式，讓 owner 可以安全地轉移所有權
6. 使用修飾器保護 withdrawAll 函式

這些修復措施可以有效防止因資源未正確初始化或初始化方式不當而導致的安全漏洞。在實際部署可升級合約或使用代理模式時，初始化邏輯需要特別注意，確保權限控制從一開始就被正確執行。
*/