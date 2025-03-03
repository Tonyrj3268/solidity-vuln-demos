// -------------------------------
// 漏洞版本：IntegerOverflowVulnerable
// -------------------------------
contract IntegerOverflowVulnerable {
    // 使用 mapping 儲存 uint256 對應的值
    mapping(uint256 => uint256) public map;
    
    // init 函式將傳入的 v 加到 map[k] 上
    // 【漏洞段落】：
    // 若 map[k] 的值加上 v 超過 uint256 可表示的最大值 (2^256 - 1)，
    // 則會發生整數溢出 (overflow)，導致結果循環到 0 開始，
    // 進而可能引起錯誤邏輯或資金損失。
    function init(uint256 k, uint256 v) public {
        map[k] += v;
    }
}

// -------------------------------
// 修正版本：IntegerOverflowFixed
// -------------------------------
contract IntegerOverflowFixed {
    // 使用 mapping 儲存 uint256 對應的值
    mapping(uint256 => uint256) public map;
    
    // init 函式使用安全加法避免整數溢出問題
    // 【修正段落】：
    // 使用 add() 函式進行安全加法運算，該函式在相加後檢查結果是否大於等於其中一個相加數，
    // 若不符合則觸發 require，從而避免 overflow 的發生。
    function init(uint256 k, uint256 v) public {
        map[k] = add(map[k], v);
    }
    
    // SafeMath 的安全加法函式
    // 【修正段落】：
    // 此函式在進行加法運算後會檢查溢出情況，確保不會出現 overflow 問題，
    // 並在檢查失敗時觸發 revert，保證數學運算的正確性。
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}
