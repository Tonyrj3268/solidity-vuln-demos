/*
SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/*
修正說明:
為了解決 Improper Exception Handling in a Loop 漏洞，我們將直接轉帳的操作改為累積用戶可提領的餘額，採用 pull 模式讓用戶自行提款。
這樣一來，即使某筆操作因惡意合約或其他因素失敗，也不會直接執行 Ether 轉帳，而是累積到合約內，使用者可以在日後分多次提款，降低單筆交易出錯的風險與大量 gas 浪費的可能性。
*/

contract CallInLoop {
    // 儲存每個地址累積的提款金額，地址型別保持為一般 address
    mapping(address => uint) public credits;

    // 儲存目標地址陣列，這裡存放的依然是 payable 地址
    address payable[] public destinations;

    // 管理者可以設定或更新目標地址（此處未加存取控制，部署上線時請謹慎處理）
    function setDestinations(address payable[] memory newDestinations) public {
        destinations = newDestinations;
    }

    // 私有函式：累積給定地址的可提領金額
    function allowForPull(address receiver, uint amount) private {
        credits[receiver] += amount;
    }

    // 修改過的函式：循環中僅累積金額，而不直接轉帳
    function bad() external payable {
        // 正確使用迴圈條件
        for (uint i = 0; i < destinations.length; i++) {
            allowForPull(destinations[i], i); // 累積操作，不做直接轉帳
        }
    }

    // 提款函式：pull 模式讓使用者自行提領累積金額
    function withdrawCredits() public {
        uint amount = credits[msg.sender];
        require(amount != 0, "No credits available");
        require(address(this).balance >= amount, "Insufficient contract balance");
        credits[msg.sender] = 0;
        // 將 msg.sender 強制轉換為 payable address 進行提款
        payable(msg.sender).transfer(amount);
    }
}
