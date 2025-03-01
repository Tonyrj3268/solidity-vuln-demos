pragma solidity ^0.4.24;

// 漏洞名稱：Improper Exception Handling in a Loop
// 描述：當一個交易中含有過多操作（例如迴圈中進行多次轉帳），若其中任何一個操作失敗，整個交易會回滾，導致已消耗的 gas 無法退回。
// 此漏洞會增加交易成本，並在部分操作失敗時導致所有操作都必須重新執行，因此建議將交易拆分成較小的部分處理。

//===============================================
// 漏洞版本：CallsInLoopVulnerable
//===============================================
contract CallsInLoopVulnerable {
    // 儲存目標地址的陣列
    address[] public destinations;
    
    // 建構子：初始化目標地址陣列
    constructor(address[] _destinations) public {
        destinations = _destinations;
    }
    
    // 漏洞函式：bad
    // 在此函式中，使用迴圈直接對每個地址進行轉帳操作，
    // 若任一地址轉帳失敗（例如因為合約拒絕接受轉帳或其他原因），
    // 則整筆交易會回滾，先前的所有轉帳也會失效，
    // 並且消耗的 gas 不可退回，增加了使用者的成本風險。
    function bad() external {
        // 注意：正確的迴圈條件應為 i < destinations.length
        for (uint i = 0; i < destinations.length; i++) {
            // 【漏洞段落】：直接在迴圈中使用 transfer 轉帳
            // 若其中一個 transfer 發生例外，將導致整筆交易回滾
            destinations[i].transfer(i);
        }
    }
}

//===============================================
// 修正版本：CallInLoopSafe
//===============================================
contract CallInLoopSafe {
    // 儲存目標地址的陣列
    address[] public destinations;
    // 利用 mapping 記錄每個地址累積的待提領金額
    mapping(address => uint) public credits;
    
    // 建構子：初始化目標地址陣列
    constructor(address[] _destinations) public {
        destinations = _destinations;
    }
    
    // allowForPull：將待轉帳金額累積到 credits 中
    // 此方法採用「pull 模式」來取代直接轉帳，將原本可能失敗的外部轉帳操作拆分成
    // 兩個獨立步驟：累積金額與使用者自行提領，從而避免在迴圈中直接進行外部呼叫，
    // 降低因單一操作失敗而導致整筆交易回滾的風險。
    function allowForPull(address receiver, uint amount) private {
        credits[receiver] += amount;
    }
    
    // 改良後的函式：bad
    // 在此函式中，不直接進行轉帳，而是透過迴圈累積各目標地址應得的金額，
    // 後續由各地址主動呼叫 withdrawCredits() 提領金額，這樣即使某個累積步驟失敗，
    // 也不會影響整個交易的成功執行。
    function bad() external {
        // 正確的迴圈條件：i < destinations.length
        for (uint i = 0; i < destinations.length; i++) {
            // 【修正段落】：將轉帳金額累積到 credits，而非立即轉帳
            allowForPull(destinations[i], i);
        }
    }
    
    // withdrawCredits：讓使用者自行提領累積的金額
    // 此函式先檢查累積金額和合約餘額，再清除該使用者的累積數值，
    // 最後再進行轉帳操作，符合 Checks-Effects-Interactions 原則，
    // 降低因外部呼叫失敗而導致重入或其他意外狀態的風險。
    function withdrawCredits() public {
        uint amount = credits[msg.sender];
        require(amount != 0, "無可提領金額");
        require(address(this).balance >= amount, "合約餘額不足");
        
        // 【修正段落】：先清空累積金額，再執行轉帳操作，確保狀態一致
        credits[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    // 接收 Ether 的 fallback 函式
    function() external payable {}
}
