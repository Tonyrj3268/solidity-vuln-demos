// -------------------------------
// 漏洞版本：TestVulnerable
// -------------------------------
contract TestVulnerable {
    // 【漏洞段落】：
    // 在部署合約時將 block.timestamp 存入變數 time，
    // 此值一經設定便不會改變，但實際上區塊時間可由礦工在一定範圍內操縱，
    // 若依此靜態的時間作為事件控制（例如判斷餘數條件），可能被惡意礦工利用，
    // 導致合約行為不如預期。
    uint time = block.timestamp;

    // pay() 函式根據存取的 time 變數決定是否付款
    function pay() public {
        // 【漏洞段落】：
        // 使用存取的 time 進行餘數判斷，若條件滿足則付款，
        // 但此條件其實是在部署時就已固定，不隨區塊實際時間更新，
        // 因而可能引起預期之外的行為或被礦工操縱部署時機來影響合約狀態。
        if (time % 2 == 1) {
            // 注意：send() 只會回傳 false 而非 revert，實務上建議使用 transfer() 或檢查回傳值
            msg.sender.send(100);
        }
    }
}

// -------------------------------
// 修正版本：TestFixed
// -------------------------------
contract TestFixed {
    // 【修正段落】：
    // 移除在部署時固定 block.timestamp 的做法，
    // 改為在每次呼叫 pay() 時直接使用動態的區塊變數，
    // 但要注意的是 block.timestamp 仍存在被礦工微調的風險，
    // 因此若需要作為事件控制的依據，應考慮使用其他不易操縱的機制，
    // 例如透過 commit-reveal 模式產生隨機性，或改用 block.number（不過其用途不同）。
    //
    // 此範例修正為：直接在 pay() 中使用當前區塊資訊，降低因部署時固定值導致的不確定性，
    // 並以 block.number 替代 block.timestamp 作為條件判斷的依據（因為 block.number 較難被礦工操縱）。
    function pay() public {
        // 【修正段落】：
        // 改用 block.number 作為條件依據，雖然仍非完美隨機來源，但較難被操縱，
        // 並且不會因為部署時固定的時間而導致不合時宜的行為。
        if (block.number % 2 == 1) {
            // 為了安全，建議使用 transfer() 替代 send()，
            // 若失敗則會自動 revert，避免不必要的風險。
            msg.sender.transfer(100);
        }
    }

    // fallback 函式，允許合約接收 Ether
    function() external payable {}
}
