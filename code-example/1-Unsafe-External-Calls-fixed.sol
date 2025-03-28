// SPDX-License-Identifier: UNLICENSED
// Solidity >=0.8.0
pragma solidity >=0.8.0;

/*
修正版的合約 Safe 使用兩種手法防範 reentrancy 攻擊：
1. 採用 Checks-Effects-Interactions 模式，先更新狀態，再進行外部呼叫。
2. 本示例僅修正主要漏洞，未使用 ReentrancyGuard；若需更高安全性可引入 OpenZeppelin 的 ReentrancyGuard。

修正重點:
- withdraw 函式中先將 balances[msg.sender] 設為 0，再進行外部呼叫。

測試攻擊:
1. 攻擊者部署 AttackerFixed 合約並指定 Safe 合約位址 (需為 payable address)。
2. 當攻擊者呼叫 attack() 將 Ether 存入 Safe 合約後，再嘗試 withdraw，重入攻擊因狀態先更新而失敗。

警告修正：
- 修改 AttackerFixed 建構子，將 _safeAddress 參數型別改為 address payable，以解決編譯錯誤。
*/

contract Safe {
    // 狀態變數，記錄每個地址所存放的 Ether
    mapping(address => uint256) public balances;

    // 存款函式
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // 修正後：先更新狀態，再進行外部呼叫，避免 reentrancy 攻擊
    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient funds");

        // 先更新狀態，防止 reentrancy
        balances[msg.sender] = 0;

        // 安全地進行外部呼叫
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Ether transfer failed");
    }

    // 接收 Ether 函式
    receive() external payable {}
}

// 攻擊合約範例，用以測試修正後的合約是否安全
contract AttackerFixed {
    Safe public safeContract;

    // 在部署時注入 Safe 合約位址，此處修改型別為 address payable 以符合要求
    constructor(address payable _safeAddress) {
        safeContract = Safe(_safeAddress);
    }

    // 嘗試進行攻擊：呼叫 withdraw()
    // 由於 Safe 合約已先更新狀態，因此無法進行 reentrancy 攻擊
    function attack() external payable {
        require(msg.value > 0, "Need to send some Ether");
        // 存款到 Safe 合約
        safeContract.deposit{value: msg.value}();
        // 呼叫 withdraw，攻擊應該失敗
        safeContract.withdraw();
    }

    // 提取合約中的 Ether
    function collect() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    // 接收 Ether 函式
    receive() external payable {}
}
