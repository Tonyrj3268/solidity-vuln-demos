/*
修正後程式碼說明:
修正 Improper Declaration or Initialization 漏洞核心在於初始設定關鍵變數 owner，必須在部署時就賦予其正確的值，以防止任何人利用未初始化的情形奪取合約控制權。
*/

contract FixedContract {
    // 修正重點: 正確初始化 owner，在部署時即設為合約部署者
    address public owner;

    // 正確的 constructor 初始化
    constructor() {
        owner = msg.sender; // 將 owner 設為合約部署者
    }

    // 合約功能: 存款
    function deposit() public payable {}

    // 合約功能: 提款，僅允許 owner 執行
    function withdraw(uint amount) public {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(amount);
    }
}
