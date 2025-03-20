// 此為修正後程式碼，採用安全減法檢查，避免發生 Integer Underflow

contract IntegerOverflowMappingSym1 {
    mapping(uint256 => uint256) public map;

    // 使用 SafeMath 模式的減法函式進行檢查，避免 underflow
    function init(uint256 k, uint256 v) public {
        // 修正重點：改為先執行安全檢查之後，再進行減法運算
        map[k] = sub(map[k], v);
    }

    // 從 SafeMath 改寫之 safe subtraction 函式
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // require 使用英文訊息避免編譯錯誤
        require(a >= b, "Underflow error");
        return a - b;
    }
}

/*
說明：
1. 在 init() 中，原本直接使用 map[k] -= v 可能導致 underflow 的漏洞已被修正，改用 sub() 函式進行安全檢查。
2. 當 map[k] 的數值小於傳入的 v 時，sub() 會觸發 require，阻止運算繼續執行，進而避免 underflow 狀況的發生。
3. 此修正方法適用於所有需要避免 underflow 的情境。
*/
