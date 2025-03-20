// 修正後的合約程式碼：利用 SafeMath 風格的加法來避免整數溢位

contract IntegerOverflowMappingSym1 {
    // 狀態變數：mapping 用於累加值
    mapping(uint256 => uint256) public map;
    
    // 修正後的 init 函式使用安全加法，避免溢位
    function init(uint256 k, uint256 v) public {
        map[k] = add(map[k], v);
    }
    
    // 安全的加法函式，模仿 SafeMath 的加法，檢查是否溢位
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow"); // 檢查是否因加法導致溢位，若溢位則 revert
        return c;
    }
}
