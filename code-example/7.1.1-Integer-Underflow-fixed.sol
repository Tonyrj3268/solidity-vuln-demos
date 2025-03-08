// 以下為修正後的程式碼，利用下溢檢查避免 underflow 問題

contract IntegerOverflowMappingSym1 {
    mapping(uint256 => uint256) map;

    // 改良後的 init 函式，在執行減法前呼叫 sub 函式進行檢查
    function init(uint256 k, uint256 v) public {
        // 此處將呼叫 sub 函式，該函式會先檢查 a 是否大於等於 b
        map[k] = sub(map[k], v);
    }

    // SafeMath 版本的 sub 函式
    // 修正重點：require 條件改為 a >= b，如果不滿足則 revert 並顯示錯誤訊息
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "Underflow error: a is less than b");
        return a - b;
    }
}
