// 以下為修正後的程式碼，解決因 gas 控制不嚴謹而可能引起的漏洞

contract Relayer {
    uint transactionId;
    struct Tx {
        bytes data;
        bool executed;
    }
    mapping (uint => Tx) transactions;
    
    // 修正: 新增 _gasLimit 參數，由使用者指定執行 Target.execute 的最低 gas 限制
    function relay(Target target, bytes memory _data, uint _gasLimit) public {
        // 重放保護：不允許相同交易被執行兩次
        require(transactions[transactionId].executed == false, "same transaction twice");
        transactions[transactionId].data = _data;
        transactions[transactionId].executed = true;
        transactionId += 1;
        
        // 修正: 在使用 call 時傳入 _gasLimit，Target 合約也會檢查剩餘 gas
        address(target).call(abi.encodeWithSignature("execute(bytes,uint256)", _data, _gasLimit));
    }
}

// 修正後的 Target 合約，增加了 gas 檢查機制
contract Target {
    // 修正: execute() 現接收 _gasLimit 參數，並先檢查目前剩餘的 gas 是否足夠
    function execute(bytes memory _data, uint _gasLimit) public {
        require(gasleft() >= _gasLimit, "not enough gas");
        // Execute 合約程式碼
    }
}
