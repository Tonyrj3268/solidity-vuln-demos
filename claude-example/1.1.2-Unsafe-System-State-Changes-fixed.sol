interface Called {
    function f() external;
}

contract Fixed {
    uint public counter;
    
    event Counter(uint value);
    
    // 已修復的函式：先完成所有狀態變更並發出事件，然後再進行外部呼叫
    function bug(Called d){
        counter += 1;         // 先更改狀態
        emit Counter(counter); // 立即發出事件，確認狀態變更
        d.f();                // 最後才呼叫外部合約，避免在狀態不完整時被重入
    }
    
    // 其他合約功能...
    function getCounter() public view returns (uint) {
        return counter;
    }
}

/*
修復說明：
修復方法遵循「檢查-效果-互動」(Checks-Effects-Interactions)模式：
1. 先完成所有內部狀態的變更（counter += 1）
2. 發出相關事件，確認狀態變更已完成（emit Counter(counter)）
3. 最後才進行外部呼叫（d.f()）

這樣即使外部呼叫重新進入合約，所有相關的狀態變更和事件已經完成，
不會導致非預期的狀態混亂。即使攻擊者嘗試重入攻擊，也不會破壞合約的邏輯流程，
因為每次新的函式呼叫都會看到完整更新後的狀態。

此修復不會影響合約的正常功能，但有效防止了狀態被干擾的風險。
*/