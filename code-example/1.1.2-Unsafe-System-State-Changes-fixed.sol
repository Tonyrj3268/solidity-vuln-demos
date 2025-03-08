// 修正後的合約：
// 因為原先漏洞在於在狀態改變後呼叫外部合約，導致可能透過重入改變系統狀態，
// 修正方式是將所有內部狀態變更以及事件發送均完成後，再進行外部呼叫，
// 如下所示：

interface ICalled {
    function f() external;
}

contract Fixed {
    uint256 public counter;
    event Counter(uint256 indexed newCounter);

    function bug(ICalled d) public {
        // 先更新狀態
        counter += 1;
        
        // 先發送事件，以紀錄系統狀態改變，確保在外部呼叫前穩定
        emit Counter(counter);
        
        // 最後進行外部呼叫
        d.f();
    }
}
