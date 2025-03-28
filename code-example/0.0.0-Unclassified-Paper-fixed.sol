pragma solidity >=0.8.0;

// SPDX-License-Identifier: UNLICENSED

// FixedBank 合約：修正 reentrancy 漏洞
// 修正方式：使用檢查-效果-互動模式，先更新狀態變數後再呼叫外部函式，並加入簡單的 reentrancy guard

contract FixedBank {
    mapping(address => uint256) public balances;
    bool private locked; // reentrancy lock 變數

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    // 存入 Ether
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // 修正後的 withdraw 函數：先更新狀態，再呼叫外部函式；套用 nonReentrant 修飾子防止重入攻擊
    function withdraw() public nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        // 先更新狀態，避免 reentrancy
        balances[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // 定義 receive 函數以接收 Ether，避免警告
    receive() external payable {}
}

// FixedAttacker 合約：由於 FixedBank 修正了漏洞，攻擊將失敗
// 攻擊步驟與 VulnerableBank 攻擊相同，但 withdraw 函數安全不會被重入

contract FixedAttacker {
    FixedBank public fixedBank;
    uint256 public attackCount = 0;

    // 同樣將構造子接收參數型態改為 address payable 以避免錯誤
    constructor(address payable _fixedBank) {
        fixedBank = FixedBank(_fixedBank);
    }

    // 嘗試攻擊：存入 Ether 並呼叫 withdraw
    function attack() public payable {
        require(msg.value >= 1 ether, "Need at least 1 Ether");
        fixedBank.deposit{value: msg.value}();
        fixedBank.withdraw();
    }

    // receive 函數用來接收 Ether，避免 fallback 混淆
    receive() external payable {}

    // fallback 函數中嘗試重入，但由於 nonReentrant 保護，重入將會失敗
    fallback() external payable {
        if (address(fixedBank).balance >= 1 ether && attackCount < 3) {
            attackCount += 1;
            fixedBank.withdraw();
        }
    }
}
