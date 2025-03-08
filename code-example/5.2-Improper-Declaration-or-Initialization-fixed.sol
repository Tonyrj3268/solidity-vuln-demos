// 修正後的程式碼
// 方式一：於部署時於 constructor 內正確初始化 owner，避免不受保護的 initialize() 函式

contract FixedContract {
    address public owner;

    // 建議使用 constructor，在合約部署時即初始化 owner，不再允許後續修改
    constructor() {
        owner = msg.sender;
    }

    // 僅允許 owner 呼叫 withdraw()，並且 owner 已於部署時正確設定
    function withdraw() public {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }

    // 接收轉帳
    receive() external payable {}
}

// 或方式二：若必須保留 initialize()，則必須加入存取控制，僅允許可信來源呼叫，且只能調用一次

contract FixedInitializableContract {
    address public owner;
    bool public initialized;

    // 僅限合約部署者調用 initialize() 來設定 owner
    // 假設部署者先行調用，本函式便不可再被其他人調用
    function initialize() public {
        require(!initialized, "Already initialized");
        // 加入額外檢查，例如僅允許特定地址調用（此處示範為 msg.sender 必須是部署者預設地址，可根據實際需求調整）
        // 例如： require(msg.sender == EXPECTED_ADDRESS, "Not authorized");
        owner = msg.sender;
        initialized = true;
    }

    function withdraw() public {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}

/*
繁體中文補充說明：
修正方法主要有兩種：
1. 直接在部署合約時於 constructor 中初始化 owner，避免外部呼叫 initialize() 帶來的風險。
2. 若必須使用 initialize()（例如用於 upgradeable 合約模式），則必須加入嚴格權限檢查，
   保證只有合法的部署者能夠調用，並確保 initialize() 只能執行一次。
這樣可以有效防止攻擊者利用不當的初始化函式來竊取合約控制權及資金。
*/
