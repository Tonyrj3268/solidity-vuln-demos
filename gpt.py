from openai import OpenAI
import pandas as pd
import os
from pydantic import BaseModel
from bs4 import BeautifulSoup

# 讀取 Excel 檔案
excel_path = 'output.xlsx'
df = pd.read_excel(excel_path)
target_index = ["1.1.1", "1.1.2", "2.1.2", "3.1", "4.2", "5.2", "6.1.1", "6.1.4", "7.1.1", "7.1.2"]
output_folder = 'code-examples'
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

class SolidityCodeExample(BaseModel):
    attack_code: str
    vulnerability_code: str
    fixed_code: str

def chat_completion(messages:str) -> SolidityCodeExample:
    response = client.beta.chat.completions.parse(
        model="o3-mini-2025-01-31",
        messages=[{"role": "system", "content": "You are a solidity developer. Please generate attack code, vulnerability code, and fixed code for the following solidity code."},
                  {"role": "user", "content": messages},],
        response_format=SolidityCodeExample,
        temperature=0,
    )
    return response.choices[0].message.parsed

def clean_code(code:str):
    soup = BeautifulSoup(code, 'html.parser')
    # 使用 separator 參數可保留換行格式
    plain_code = soup.get_text(separator="\n")
    filtered_lines = [line for line in plain_code.splitlines() if line.strip() != ""]
    result = "\n".join(filtered_lines)
    return result

for idx, row in df.iterrows():
    index_val = row['index'] if 'index' in row and not pd.isna(row['index']) else idx
    print(f"Processing index {index_val}")
    if index_val not in target_index:
        continue
    defect_name = str(row['defectname']) if 'defectname' in row else ""
    description = str(row['description']) if 'description' in row else ""
    original_code = clean_code(str(row['Vulnerable']) if 'Vulnerable' in row else "")
    fixed_code = clean_code(str(row['Fixed']) if 'Fixed' in row else "")

    prompt_text = f"""這個漏洞名稱為
        {defect_name}
        描述為
        {description}

        以下是原文認為有問題的code
        {original_code}

        以下是修正後的程式碼
        {fixed_code}

        請分別生成
        1. attack_code
        - 程式碼部分可使用最小可行的攻擊範例（如需多步驟呼叫或部署前置動作，請一併敘述）。
        2. vulnerability_code
        - 請把程式碼漏洞重點部位（如狀態變數、函式）標示出來並加以註解。
        3. fixed_code

        注意：
        1. 在攻擊手法和對應漏洞和修復段落使用「繁體中文」補充描述
        2. 如果你認為該修正無法充分展示出這個漏洞造成的理由，或是該程式碼不夠完整，請更改原文的程式碼並做出完整的補充和解釋
        3. 如果這個漏洞和指定的版本無關，不要在第一行寫出任何版本和pragma solidity以避免誤會
        4. 如果漏洞與某些特定版本（Solidity 或第三方 Library）有關，請說明;
        4. 關於solidity的require使用，請記得在msg使用英文撰寫避免編譯錯誤
        """
    
    solution = chat_completion(prompt_text)
    code_types = ['attack', 'vulnerability', 'fixed'] 
    codes = [solution.attack_code, solution.vulnerability_code, solution.fixed_code]
    for type, code in zip(code_types, codes):
        file_name = f"{index_val}-{defect_name.replace(' ', '-')}-{type}.sol"
        file_path = os.path.join(output_folder, file_name)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(code)