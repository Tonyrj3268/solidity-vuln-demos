// 修正後程式碼：
// 將迴圈中的即時轉帳修改為先記錄應提領的金額，讓使用者自行提領，避免單一失敗導致全部回退

contract CallInLoop {
    address[] public destinations;
    mapping(address => uint) public credits; // 每個地址的累積可提領金額

    // 在部署合約時設定受款方地址
    constructor(address[] memory newDestinations) public {
        destinations = newDestinations;
    }

    // 將款項累計到 credits 中，改為允許用戶自行提現
    function allowForPull(address receiver, uint amount) private {
        credits[receiver] += amount;
    }

    // 修改後的函式，不直接轉帳而是累計 credits，避免其中一筆交易失敗導致全部回退
    function bad() external {
        for (uint i = 0; i < destinations.length; i++) { // 修正迴圈條件
            // 將應付金額累計，若某一付款失敗不會影響其他付款
            allowForPull(destinations[i], i);
        }
    }

    // 供受款方自行提領累計的款項
    function withdrawCredits() public {
        uint amount = credits[msg.sender];
        require(amount != 0, "No credits available");
        require(address(this).balance >= amount, "Insufficient contract balance");
        credits[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    // 為合約注入資金的函式，僅供測試用
    function deposit() external payable {}
}
