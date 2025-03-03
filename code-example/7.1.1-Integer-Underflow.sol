// -------------------------------
// 漏洞版本：IntegerUnderflowVulnerable
// -------------------------------
contract IntegerUnderflowVulnerable {
    // 使用 mapping 儲存 uint256 對應的值
    mapping(uint256 => uint256) public map;
    
    // init 函式將傳入的 v 從 map[k] 減去
    // 【漏洞段落】：
    // 若 map[k] 的值小於 v，則在執行 map[k] -= v 時會發生整數下溢（underflow），
    // 此時運算結果會循環到 uint256 的最大值，導致意外且不可預期的行為。
    function init(uint256 k, uint256 v) public {
        map[k] -= v;
    }
}

// -------------------------------
// 修正版本：IntegerUnderflowFixed
// -------------------------------
contract IntegerUnderflowFixed {
    // 使用 mapping 儲存 uint256 對應的值
    mapping(uint256 => uint256) public map;
    
    // init 函式使用 safe subtraction 避免整數下溢問題
    // 【修正段落】：
    // 使用 sub() 函式進行安全減法，在執行減法前會檢查 a 是否大於等於 b，
    // 若檢查失敗則會 revert，從而避免發生 underflow 的風險。
    function init(uint256 k, uint256 v) public {
        map[k] = sub(map[k], v);
    }
    
    // SafeMath 的安全減法函式
    // 【修正段落】：
    // 此函式在進行減法運算前，先檢查 b 是否大於 a，
    // 若是，則觸發 require，避免 underflow 發生。
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Underflow error: subtraction would result in negative value");
        return a - b;
    }
}
