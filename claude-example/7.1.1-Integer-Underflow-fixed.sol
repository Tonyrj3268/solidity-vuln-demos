// 修復後的合約 - 防止 Integer Underflow
contract IntegerOverflowMappingSym1 {
    mapping(uint256 => uint256) map;
    
    // 修復後的函式：使用安全的減法函式替代直接減法
    function init(uint256 k, uint256 v) public {
        // 使用安全的減法函式，會在發生下溢時拋出錯誤
        map[k] = sub(map[k], v);
    }
    
    // 安全減法函式：在執行減法前檢查是否會發生下溢
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // 檢查：確保 b 不大於 a，否則會下溢
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    
    // 更現代的替代方案（Solidity 0.8.0+）：
    // function init(uint256 k, uint256 v) public {
    //     // 0.8.0+ 版本會自動檢查算術操作溢出
    //     map[k] -= v;
    // }
}

/*
修復說明：
1. 主要修復方式是引入安全的減法函式 sub()，在減法前進行檢查
2. 當 b > a 時，減法會導致下溢，所以添加了 require(b <= a) 條件
3. 注意 SafeMath 庫有些實現使用 assert() 而非 require()，但 require() 更合適，因為：
   - require() 用於驗證用戶輸入或外部條件，會退還未使用的 gas
   - assert() 用於檢查不應該發生的內部錯誤，會消耗所有 gas

版本說明：
- 在 Solidity 0.8.0 之前，需使用 SafeMath 庫或自定義安全算術函式
- 從 Solidity 0.8.0 開始，編譯器會自動插入溢出檢查，但可使用 unchecked 繞過
- 即使在新版本中，明確使用安全函式也有助於程式碼清晰度和安全意識

其他安全建議：
1. 對於關鍵操作，即使在 0.8.0+ 版本中也可考慮明確使用 SafeMath
2. 徹底測試邊界情況，特別是當處理用戶提供的輸入時
3. 考慮業務邏輯上的限制，而不僅僅是技術上的防溢出
*/