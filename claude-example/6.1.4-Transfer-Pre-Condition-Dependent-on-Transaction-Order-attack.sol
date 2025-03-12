// 攻擊原理展示：Transaction Order Dependence (TOD)
// 攻擊者：MaliciousUser
// 受害者：普通用戶 NaiveUser

// 部署說明：
// 1. 首先部署 TransactionOrdering 合約
// 2. 模擬攻擊情境

/**
 * 此攻擊範例展示了交易順序依賴(TOD)的問題
 * 問題在於用戶在基於當前價格做出決定時，
 * 無法確保該價格在交易執行時仍然有效
 */

// 攻擊步驟：
// 1. NaiveUser 觀察到當前價格為 100，決定購買並發送 buy() 交易
// 2. Owner 在 NaiveUser 的交易未被挖礦前，發送 setPrice(500) 交易並提供更高的 gas price
// 3. 由於 gas price 較高，礦工優先處理 setPrice 交易
// 4. NaiveUser 的交易在價格已變為 500 後執行，導致 NaiveUser 以意料之外的高價購買

// 模擬攻擊過程的腳本
async function simulateAttack() {
    // 模擬交易
    const naiveUser = accounts[1];
    const owner = accounts[0]; // 合約擁有者
    
    console.log("初始價格:", (await contract.price()).toString());
    
    // NaiveUser 讀取價格，準備購買
    console.log("NaiveUser 讀取價格: 100");
    
    // Owner 發送高 gas price 交易，提高價格
    console.log("Owner 發送 setPrice(500) 交易，使用高 gas price");
    await contract.setPrice(500, {from: owner, gasPrice: web3.utils.toWei('50', 'gwei')});
    
    // NaiveUser 的交易在價格變更後才被處理
    console.log("NaiveUser 的購買交易現在執行");
    const result = await contract.buy({from: naiveUser, gasPrice: web3.utils.toWei('20', 'gwei')});
    
    console.log("NaiveUser 支付的價格:", (await contract.price()).toString());
    // NaiveUser 不得不以 500 的價格購買，而非最初看到的 100
}