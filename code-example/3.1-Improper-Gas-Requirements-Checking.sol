pragma solidity ^0.4.24;

/*
漏洞名稱：Improper Gas Requirements Checking
描述：
    此缺陷因缺少或錯誤檢查執行操作前所需的 gas 前提條件，導致不必要的處理及記憶體資源消耗。舉例來說，
    Solidity 提供 transfer() 與 send() 進行轉帳時會限制 2300 gas，但若採用自訂的轉帳方式，則可由變數控制 gas 限制。
    然而，預測哪一段程式碼可能因 gas 不足而失敗並非易事，一旦觸發 out-of-gas 異常，將導致不預期的行為。
    
以下提供完整的範例程式碼，分別展示漏洞版本與修正版本，
並在相應段落中以註解方式補充漏洞成因與修正原理說明。
*/

// ================================
// 漏洞版本
// ================================
contract TargetVulnerable {
    /*
    說明：
        execute() 函式中未對傳入操作所需的 gas 進行檢查，若呼叫時 gas 不足，
        則可能導致合約內部邏輯無法順利執行，進而造成執行失敗，
        或使交易消耗過多 gas 甚至回滾，影響成本管理。
    */
    function execute(bytes memory _data) public {
        // 【漏洞段落】：缺少對 gas 可用量的檢查，可能導致操作耗費過多 gas 或失敗
        // 這裡執行傳入的 _data 所代表的邏輯，但沒有預留足夠 gas
        // 可能導致執行中斷，進而浪費資源或造成不預期的行為
    }
}

contract RelayerVulnerable {
    uint public transactionId;

    struct Tx {
        bytes data;
        bool executed;
    }
    mapping (uint => Tx) public transactions;

    /*
    說明：
        relay() 函式在呼叫 TargetVulnerable 合約的 execute() 時，
        沒有指定或檢查適當的 gas 限制，完全依賴預設的 gas 轉發機制，
        這可能導致呼叫方在 gas 不足時產生 out-of-gas 異常，
        進而浪費已消耗的 gas 並可能造成交易回滾。
    */
    function relay(TargetVulnerable target, bytes memory _data) public returns (bool) {
        // replay protection; 防止同一交易被重複執行
        require(transactions[transactionId].executed == false, "same transaction twice");
        transactions[transactionId].data = _data;
        transactions[transactionId].executed = true;
        transactionId += 1;
        
        // 【漏洞段落】：呼叫 target.execute() 時未指定 gas 限制，
        // 導致無法控制轉發的 gas 數量，可能因 gas 不足而失敗
        (bool success, ) = address(target).call(abi.encodeWithSignature("execute(bytes)", _data));
        return success;
    }
}

// ================================
// 修正版本
// ================================
contract TargetFixed {
    /*
    說明：
        修正後的 execute() 函式新增了 gas 前置檢查，
        確保在執行操作前合約擁有足夠的 gas。
        若剩餘 gas 少於要求值，則直接 revert，避免後續邏輯在 gas 不足時執行。
    */
    function execute(bytes memory _data, uint _gasLimit) public {
        // 【修正段落】：先檢查剩餘 gas 是否充足，若不足則 revert
        require(gasleft() >= _gasLimit, "not enough gas");
        // 在此根據 _data 執行相應的邏輯操作，確保執行環境具備足夠 gas
    }
}

contract RelayerFixed {
    uint public transactionId;

    struct Tx {
        bytes data;
        bool executed;
    }
    mapping (uint => Tx) public transactions;

    /*
    說明：
        relay() 函式新增 _gasLimit 參數，並在呼叫 TargetFixed.execute() 時明確傳入，
        利用 call.gas(_gasLimit) 指定轉發的 gas 限制。
        這樣能夠精確控制執行操作時的 gas 供應，降低因 gas 管理不當而導致的資源浪費或異常。
    */
    function relay(TargetFixed target, bytes memory _data, uint _gasLimit) public returns (bool) {
        // replay protection; 防止同一交易被重複執行
        require(transactions[transactionId].executed == false, "same transaction twice");
        transactions[transactionId].data = _data;
        transactions[transactionId].executed = true;
        transactionId += 1;
        
        // 【修正段落】：使用 call.gas(_gasLimit) 指定外部呼叫時的 gas 限制，
        // 並且 encodeWithSignature 的函式簽章必須與 TargetFixed.execute() 定義一致，
        // 以確保 TargetFixed 在執行前能檢查剩餘 gas 是否充足
        (bool success, ) = address(target).call.gas(_gasLimit)(abi.encodeWithSignature("execute(bytes,uint256)", _data, _gasLimit));
        return success;
    }
}
