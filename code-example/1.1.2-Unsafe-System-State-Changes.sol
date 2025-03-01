pragma solidity ^0.4.24;

// 假設 Called 是一個介面或合約，其包含函式 f()
// 攻擊者可能透過 f() 導致合約狀態異常變更
contract Called {
    function f() public;
}

contract TestContract {
    // 計數器，代表某種狀態
    uint public counter;
    // 事件用於記錄 counter 變化
    event Counter(uint counter);

    //===============================================
    // 漏洞版本：Unsafe System State Changes
    //===============================================
    // 描述：
    // 在此函式中，counter 先被增加後呼叫外部合約 d.f()，
    // 接著才 emit Counter 事件。由於 d.f() 是外部呼叫，
    // 若該呼叫改變了系統內部狀態或導致非預期行為，
    // 會造成合約狀態處於不一致或意外狀態，
    // 導致後續可能出現效能或可用性問題。
    function bugVulnerable(Called d) public {
        // 【漏洞段落】：先更新狀態（counter += 1）
        counter += 1;
        
        // 【漏洞段落】：外部呼叫發生於狀態更新與事件記錄之間，
        // 攻擊者可利用 d.f() 改變合約的運作狀態
        d.f();
        
        // 【漏洞段落】：最後發出事件，但此時狀態可能已被外部干擾
        emit Counter(counter);
    }

    //===============================================
    // 修正版本：安全的 System State Changes
    //===============================================
    // 修正重點：
    // 依循 Checks-Effects-Interactions 原則，
    // 在執行外部呼叫前，應完成所有內部狀態的更新及事件記錄。
    // 因此，先更新狀態、發出事件，再進行外部呼叫，
    // 這樣可以降低外部呼叫對系統狀態產生的干擾。
    function bugSafe(Called d) public {
        // 【修正段落】：先更新狀態（counter += 1）並發出事件，確保內部狀態已被妥善記錄
        counter += 1;
        emit Counter(counter);
        
        // 【修正段落】：最後進行外部呼叫，避免外部呼叫在狀態未更新時引起異常狀態
        d.f();
    }
}
