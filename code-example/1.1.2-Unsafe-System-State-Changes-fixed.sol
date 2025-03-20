/*
  修正後程式碼說明：
  為避免由外部呼叫導致 reentrancy 攻擊，我們調整了 bug 函式內的指令順序，
  先完成狀態變數更新與事件發送，再執行外部呼叫，符合 Checks-Effects-Interactions 原則。
  此調整可使得在外部呼叫發生前，狀態與事件順序均已正確記錄，降低系統被置於非預期狀態的風險。
*/

interface ICalled {
    function f() external;
}

contract Fixed {
    uint256 public counter;
    event Counter(uint256 count);

    // 修正後的 bug 函式：先發送事件，再進行外部呼叫
    function bug(ICalled d) public {
        counter += 1;           // 狀態變數改變
        emit Counter(counter);  // 立即發出事件，記錄正確狀態
        d.f();                  // 外部呼叫放在最後執行，降低 reentrancy 可能影響事件順序
    }
}

/*
  說明補充：
  在此修正方案中，即便攻擊者透過外部呼叫重入，也無法改變已發出的事件與狀態更新之先後順序，
  從而有效降低了透過重入攻擊置系統於非預期狀態的風險。
*/
