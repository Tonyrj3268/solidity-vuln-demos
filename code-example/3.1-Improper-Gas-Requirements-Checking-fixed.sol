/*
修正後的程式碼
修正描述: 為避免因傳遞到 Target.execute 時 gas 不足，修正的方式為在 Relayer 中加入 gas 限制參數，並在 Target.execute 中檢查剩餘的 gas 是否達到要求。
*/

// 修正後的 Relayer 合約
contract Relayer {
    uint public transactionId;
    
    struct Tx {
        bytes data;
        bool executed;
    }
    
    mapping (uint => Tx) public transactions;
    
    // 修正點: 新增 _gasLimit 參數，透過 call 方式明確設定傳遞到 Target.execute 的 gas 限制
    function relay(Target target, bytes memory _data, uint _gasLimit) public returns (bool) {
        // Replay protection; 防止重複執行相同交易
        require(transactions[transactionId].executed == false, "same transaction twice");
        transactions[transactionId].data = _data;
        transactions[transactionId].executed = true;
        transactionId += 1;
        
        // 呼叫 Target.execute 時，同時傳入 _gasLimit 作為運行所需的最低 gas 限制
        (bool success, ) = address(target).call(abi.encodeWithSignature("execute(bytes,uint256)", _data, _gasLimit));
        return success;
    }
}

// 修正後的 Target 合約
contract Target {
    // 修正點: 在執行前確認剩餘 gas 數量達到要求，避免因運算不足導致意外中斷
    function execute(bytes memory _data, uint _gasLimit) public {
        // 檢查剩餘 gas 是否充足
        require(gasleft() >= _gasLimit, "not enough gas");
        
        // 模擬執行需要花費資源的操作
        uint sum = 0;
        for (uint i = 0; i < 100000; i++) {
            sum += i;
        }
    }
}
