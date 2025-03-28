// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
  已修正版本: FixedBank
  修正方式: 在 withdraw() 函式中採用 checks-effects-interactions 模式，
         先更新使用者狀態，再進行外部呼叫 (轉帳) 動作，避免重入攻擊。
  測試步驟:
         1. 部署 FixedBank 合約。
         2. 部署 ReentrancyAttackFixed 攻擊合約，傳入 FixedBank 的 payable address。
         3. 攻擊者存款後呼叫 attack() 發動攻擊，但因先更新狀態，重入失效。
  注意:
         1. 修改 constructor 參數型態為 address payable 以符合 Solidity >=0.8.0 的要求。
         2. 為避免警告，加入 receive() 函式以正確接收 Ether。
*/

contract FixedBank {
    // 狀態變數記錄各使用者餘額
    mapping(address => uint) public balances;

    // 存款函式
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // 已修正 withdraw() 函式，先更新狀態，再進行外部呼叫
    function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // 先更新狀態，避免 reentrancy
        balances[msg.sender] -= _amount;

        // 執行外部呼叫轉帳
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Transfer failed");
    }

    // 補上 receive() 函式避免警告
    receive() external payable {}
}

// 模擬攻擊合約，但由於 FixedBank 採用 checks-effects-interactions 模式，攻擊無效
contract ReentrancyAttackFixed {
    FixedBank public bank;
    address public owner;

    // 修改 constructor 參數為 address payable
    constructor(address payable _bank) {
        bank = FixedBank(_bank);
        owner = msg.sender;
    }

    // 攻擊入口：先存款後觸發 withdraw
    function attack() external payable {
        require(msg.value >= 1 ether, "Need at least 1 ether");
        bank.deposit{value: msg.value}();
        bank.withdraw(msg.value);
    }

    // 加入 receive() 函式以避免警告
    receive() external payable {}

    // fallback() 嘗試重入 attack，但因狀態已更新而無法成功
    fallback() external payable {
        if (address(bank).balance >= 1 ether) {
            bank.withdraw(1 ether);
        }
    }

    // 將合約中的 Ether 提領至 owner
    function collect() public {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}
