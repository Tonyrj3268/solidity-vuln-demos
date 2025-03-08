// 以下程式碼示範修正後的版本，藉由 SafeMath 的加法檢查避免整數溢位

contract IntegerOverflowMappingSym1 {
    mapping(uint256 => uint256) map;

    // 使用安全加法來避免 overflow
    function init(uint256 k, uint256 v) public {
        // 呼叫 add 函式來確保加法安全
        map[k] = add(map[k], v);
    }

    // 使用自定義的 add 函式，模仿 SafeMath 庫來進行加法的 overflow 檢查
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

// 補充說明：
// 此修正版本透過檢查加法後的結果是否大於或等於其中一個加數，
// 避免當加數接近 uint256 最大值時產生 overflow 的問題。這種檢查適用於 Solidity 版本未內建溢位保護的情況。