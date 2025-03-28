import os
import textwrap

import pandas as pd
import solcx
from bs4 import BeautifulSoup
from openai import OpenAI
from pydantic import BaseModel


class SolidityCodeExample(BaseModel):
    vulnerability_code: str
    fixed_code: str


def chat_completion(client: OpenAI, messages: list) -> SolidityCodeExample:
    # 此處假設 API 接收完整的 messages 列表
    response = client.beta.chat.completions.parse(
        model="o3-mini-2025-01-31",
        messages=messages,
        response_format=SolidityCodeExample,
    )
    return response.choices[0].message.parsed


def add_user_message(
    client: OpenAI, conversation: list, user_msg: str
) -> SolidityCodeExample:
    conversation.append({"role": "user", "content": user_msg})
    answer = chat_completion(client, conversation)
    # 假設 answer 為 SolidityCodeExample 型態，需轉為字串再儲存回對話中
    conversation.append({"role": "assistant", "content": answer.model_dump_json()})
    return answer


def clean_code(code: str) -> str:
    soup = BeautifulSoup(code, "html.parser")
    plain_code = soup.get_text(separator="\n")
    filtered_lines = [line for line in plain_code.splitlines() if line.strip() != ""]
    result = "\n".join(filtered_lines)
    return result


def compile_code(code: str) -> tuple:
    """
    嘗試編譯傳入的 Solidity 程式碼。
    成功則回傳 (True, compiled_result)，失敗則回傳 (False, error_message)
    """
    try:
        compiled = solcx.compile_source(code)
        return True, compiled
    except Exception as e:
        print("編譯錯誤：", e)
        return False, str(e)


def process_code_generation(
    client: OpenAI,
    conversation: list,
    prompt_text: str,
    index_val: str,
    defect_name: str,
) -> None:
    """
    處理特定漏洞生成程式碼並嘗試編譯，若編譯失敗則回饋錯誤訊息給 GPT 進行修正。
    code_type: "vulnerability" 或 "fixed"
    """
    max_attempts = 3
    attempt = 0
    current_prompt = prompt_text

    while attempt < max_attempts:
        # 更新對話歷程並獲取生成的程式碼
        solution = add_user_message(client, conversation, current_prompt)
        codes = {
            "vulnerability": solution.vulnerability_code,
            "fixed": solution.fixed_code,
        }

        all_success = True
        error_messages = []  # 用來收集所有錯誤訊息
        for code_type, code in codes.items():

            file_name = f"{index_val}-{defect_name.replace(' ', '-')}-{code_type}.sol"
            success, compile_message = compile_code(code)
            if success:
                file_path = os.path.join(output_folder, file_name)
                print(f"{file_name} 編譯成功！")
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(code)
            else:
                print(f"{file_name} 編譯失敗，錯誤訊息：\n{compile_message}")
                all_success = False
                error_messages.append(f"{file_name} 編譯錯誤：\n{compile_message}")

        # 若兩份程式碼都通過編譯，就離開迴圈
        if all_success:
            return
        else:
            # 將所有錯誤訊息整合，作為新的 prompt 回饋給 GPT
            fix_prompt = (
                f"以下程式碼在編譯時出現錯誤：\n" + "\n".join(error_messages) + "\n"
                "請根據這些錯誤訊息修改原本的程式碼，產生一個新的程式碼版本，並保留原有漏洞或修正的意圖。"
            )
            current_prompt = fix_prompt
            attempt += 1
    raise Exception(f"嘗試 {max_attempts} 次後，仍無法生成可編譯的程式碼。")


if __name__ == "__main__":
    solcx.install_solc("0.8.0")
    solcx.set_solc_version("0.8.0")
    # 讀取 Excel 檔案
    excel_path = "output.xlsx"
    df = pd.read_excel(excel_path)
    target_index = [
        "0.0.0",
        "1",
        "1.1",
        "1.1.1",
        "1.1.2",
        "1.2",
        "1.3",
        "2.1.2",
        "3.1",
        "4.2",
        "5.2",
        "6.1.1",
        "6.1.4",
        "7.1.1",
        "7.1.2",
    ]
    last_index = "1.7.4"
    is_last_index = False
    output_folder = "code-example"
    os.makedirs(output_folder, exist_ok=True)
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    # 主流程處理
    for idx, row in df.iterrows():

        # 全局對話歷程，包含初始的 system 訊息
        conversation = [
            {
                "role": "system",
                "content": (
                    "You are a solidity developer. Please generate attack code, vulnerability code, "
                    "and fixed code for the following solidity code."
                ),
            }
        ]
        index_val = (
            row["index"] if "index" in row and not pd.isna(row["index"]) else str(idx)
        )
        if index_val == last_index:
            is_last_index = True
            break
        # if not is_last_index:
        #     continue
        defect_name = str(row["defectname"]) if "defectname" in row else ""
        description = str(row["description"]) if "description" in row else ""
        original_code = clean_code(
            str(row["Vulnerable"]) if "Vulnerable" in row else ""
        )
        fixed_code = clean_code(str(row["Fixed"]) if "Fixed" in row else "")

        prompt_text = f"""這個漏洞名稱為
        {defect_name}
        描述為
        {description}

        以下是原文認為有問題的 code：
        {original_code}

        以下是修正後的程式碼：
        {fixed_code}

        請分別生成：
        1. vulnerability_code
        - 請在同一檔案裡補上程式碼部分可使用最小可行的攻擊範例（如需多步驟呼叫或部署前置動作，請一併敘述）。
        - 請把程式碼漏洞重點部位（如狀態變數、函式）標示出來並加以註解。
        2. fixed_code
        - 請在同一檔案裡補上程式碼部分可使用最小可行的攻擊範例（如需多步驟呼叫或部署前置動作，請一併敘述）。

        注意：
        1. 請將程式碼的 pragma solidity 改為 >=0.8.0 版本。
        1. 在攻擊手法和對應漏洞和修復段落使用「繁體中文」補充描述。
        2. 如果你認為該修正無法充分展示出這個漏洞造成的理由，或是該程式碼不夠完整，請更改原文的程式碼並做出完整的補充和解釋。
        3. 如果這個漏洞和指定的版本無關，請特別在 pragma solidity 標示或說明以避免誤會。
        4. 如果漏洞與某些特定版本（Solidity 或第三方 Library）有關，請說明；關於 solidity 的 require 使用，請記得在 msg 使用英文撰寫避免編譯錯誤。

        根據Solidity >=0.8.0版本的語法規範，請記得以下內容：
        1. 若要實現接收 Ether 的 fallback 功能，應使用 fallback 或 receive 關鍵字來正確定義函數。
        """

        process_code_generation(
            client, conversation, textwrap.dedent(prompt_text), index_val, defect_name
        )
