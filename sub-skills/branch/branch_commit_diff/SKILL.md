---
name: branch_commit_diff
version: 1.0.0
description: |
  【vcs-helper 子 skill】

  觸發詞：比較分支、分支差異、branch diff、兩個分支差了什麼、
          commit 差異、哪些 commit 不同、/vcs-helper:branch_commit_diff

  偵測到上述詞彙時，提示使用者：
  「您的需求符合 /vcs-helper:branch_commit_diff（比較分支 commit 差異），是否要執行？」

  ⚠️ 等待使用者確認後才執行。直接呼叫 /vcs-helper:branch_commit_diff 則立即執行。
parent_skill: vcs-helper
---

# branch_commit_diff — 比較兩分支 commit 差異

> ⚠️ **執行前讀取並遵守：** `../../../shared/principles.md`
>
> 🔖 **版本確認：** 執行前讀取本 SKILL.md 的 frontmatter `version` 欄位，取得當前版本號（勿從記憶中取，需從檔案重新讀取），並在每次執行開頭告知使用者，例如：`[branch_commit_diff v1.0.0]`。

比較兩個 Git 分支之間的 commit 差異，以**詳細**與**精簡**兩種表格呈現，清楚標示 merge commit 的來源分支與方向。

**共用資源：**
- 核心原則：`../../../shared/principles.md`
- Git 工具：`../../../shared/scripts/git_utils.sh`
- 輸出模板：`../../../shared/templates/output.md.tmpl`

---

## 執行步驟

### Step 1：詢問分支 A

> 請輸入**分支 A**（基準分支，例如 `main`、`develop`）：

### Step 2：詢問分支 B

> 請輸入**分支 B**（比較分支，例如 `feature/login`）：

### Step 3：執行 git log 指令

```bash
git log <branchA>...<branchB> --oneline --left-right
```

- `<` 開頭 → commit 屬於**分支 A**
- `>` 開頭 → commit 屬於**分支 B**

若需指定目錄，加上 `cd <repo_path> &&`。

**指令失敗時**：完整顯示原始錯誤訊息，立即停止。

**⚠️ 資料來源鎖定**：後續所有表格內容，只能使用 git 指令的 stdout。輸出中沒有出現的資訊一律填 `—`。

---

### Step 3b：建立「feature branch commit 歸屬表」

對 Step 3 輸出中每個 **merge commit** `M`，執行：

```bash
git log M^1..M^2 --oneline
```

- `M^1`：merge commit 的第一 parent（target branch）
- `M^2`：merge commit 的第二 parent（feature branch 的 tip）
- 輸出：僅存在於 feature branch、尚未進入 target branch 的 commits

**⚠️ 錯誤處理**：若 `M^2` 不存在（fast-forward merge），指令會報錯 → 此 merge commit 的 Commit Count 填 `—`，繼續下一個。

將所有結果整理為 **lookup table**（hash → feature branch 名稱）：

```
{commit_hash → feature_branch_name（從 M 的訊息解析 source branch）}
```

例：
```
0047494d → feature/PGBINGO-355
5dc9c743 → feature/PGBINGO-355
```

此 lookup table 用於 Step 4（所屬分支判斷）與 Step 5（精簡表格折疊）。

---

### Step 4：顯示「詳細彙整資料表格」

逐行解析 git log 輸出，**輸出幾行就顯示幾列，不增不減**。

#### 解析規則

1. **方向符號**：`<` → 分支 A（`←`）、`>` → 分支 B（`→`）
2. **Merge commit 識別**：message 含 `Merge branch`、`Merge pull request`、`Merge remote` 者視為 merge，依據只能是 message 原文
3. **Merge 來源解析（嚴格）**：
   - `Merge branch 'hotfix' into main` → 來源 `hotfix`、目標 `main`
   - `Merge branch 'hotfix'`（無 into）→ 來源 `hotfix`、目標填 `—`
   - 格式不符 → Merge 資訊欄整欄填 `—`
4. **所屬分支判斷（依序）**：
   - **Merge commit**：從訊息解析 target branch（"into Y" 的 Y，去除引號）；無 into → 填 `—`
   - **Regular commit（在 Step 3b lookup table 中）**：填入對應的 feature branch 名稱
   - **Regular commit（不在 lookup table 中）**：填入最近的更新 merge commit（同方向，序號較小者）的 target branch；無相鄰 merge → 填 branchA 或 branchB 使用者輸入名稱

#### 詳細表格

| # | 方向 | Commit Hash | 所屬分支 | 類型 | Commit Message | Merge 資訊 |
|---|------|-------------|----------|------|----------------|------------|
| 1 | ← | `hash` | branchA 名稱 | merge\|commit | 原文 | 來源 → 目標 或 `—` |

**欄位說明：**

| 欄位 | 說明 |
|------|------|
| # | 序號（由新到舊） |
| 方向 | `←` 屬於分支 A，`→` 屬於分支 B |
| Commit Hash | git 輸出的短 hash（原樣複製） |
| 所屬分支 | commit 實際所屬的分支：merge commit 填 target branch；regular commit 依 Step 3b lookup table 填 feature branch，未命中填最近 merge 的 target branch |
| 類型 | `merge` 或 `commit` |
| Commit Message | git 輸出原文，不修改 |
| Merge 資訊 | 僅 merge commit 填入：`來源分支 → 目標分支`；無法解析填 `—` |

---

### Step 5：顯示「精簡彙整資料表格」

與詳細表格的差異：**依 Step 3b lookup table 將 feature branch 子 commits 折疊進對應 merge commit，以 Commit Count 欄顯示數量**。

#### 精簡規則

| 列類型 | 處理方式 | 所屬分支 | Commit Count |
|--------|---------|---------|-------------|
| Merge commit | 列出 | **Source branch**（feature branch 名稱，即 merge 訊息中 `Merge branch 'X' into Y` 的 X，去除引號；無法解析填 `—`） | Step 3b 結果的實際數量；Step 3b 失敗填 `—` |
| Regular commit（在 Step 3b lookup table 中）| **不列出**（折疊進對應 merge commit） | — | — |
| Regular commit（不在 Step 3b lookup table 中）| 列出 | 同 Step 4 所屬分支判斷規則 | `1` |

> 所屬分支的判斷以 Step 3b lookup table 為唯一依據，不以 commit 在 log 中的相對位置推斷。

#### 精簡表格

| # | 方向 | Commit Hash | 所屬分支 | 類型 | Commit Message | Merge 資訊 | Commit Count |
|---|------|-------------|----------|------|----------------|------------|--------------|
| 1 | ← | `hash` | source branch | merge | 原文 | 來源 → 目標 | `—` 或數字 |

---

### Step 6：統計摘要

```
📈 統計摘要

| 項目 | 數量 |
|------|------|
| 分支A（←）獨有 commits | N |
| 分支B（→）獨有 commits | N |
| Merge commits | N |
| 一般 commits | N |
| 總計 | N |
```

數量來源：逐行計算 git 輸出，不估算。

---

### Step 7：詢問是否輸出 .md 文件

遵循 `../../../shared/principles.md` 的通用 MD 輸出流程。

**本 skill 預設檔名格式：**
```
branch-diff_<branchA>_<branchB>_<YYYYMMDD>.md
```

套用 `../../../shared/templates/output.md.tmpl`，其中：
- `{{TITLE}}` = `Branch Diff：<branchA> vs <branchB>`
- `{{DATETIME}}` = 系統時間（`date '+%Y-%m-%d %H:%M:%S'`）
- `{{GIT_COMMAND}}` = 實際執行的完整指令
- `{{SKILL_NAME}}` = `branch_commit_diff`
- `{{SKILL_VERSION}}` = 本 SKILL.md frontmatter 的 `version` 欄位值
- `{{CONTENT}}` = 詳細表格 + 精簡表格 + 統計摘要

---

## 錯誤處理

遵循 `../../../shared/principles.md` 錯誤處理對照表。

額外規則：兩分支相同時，顯示 git 輸出為空的事實，說明無差異 commit，不推斷原因。

---

## 範例

**Step 3 git log 輸出：**
```
< a1b2c3d Merge branch 'hotfix/session' into main
< d4e5f6g fix: session timeout
> h7i8j9k feat: add login form
> l0m1n2o Merge branch 'ui/button' into feature/login
> p3q4r5s style: update button color
> t6u7v8w style: fix padding
```

**Step 3b lookup table 結果**（對每個 merge commit 執行 `git log M^1..M^2 --oneline`）：

| Merge commit | 指令 | 輸出（feature branch 子 commits） |
|---|---|---|
| a1b2c3d | `git log a1b2c3d^1..a1b2c3d^2 --oneline` | `d4e5f6g fix: session timeout` |
| l0m1n2o | `git log l0m1n2o^1..l0m1n2o^2 --oneline` | `p3q4r5s ...` `t6u7v8w ...` |

Lookup table：`d4e5f6g → hotfix/session`、`p3q4r5s → ui/button`、`t6u7v8w → ui/button`

---

**詳細表格**（6 列，對應 6 行輸出）：

| # | 方向 | Commit Hash | 所屬分支 | 類型 | Commit Message | Merge 資訊 |
|---|------|-------------|----------|------|----------------|------------|
| 1 | ← | a1b2c3d | main | merge | Merge branch 'hotfix/session' into main | hotfix/session → main |
| 2 | ← | d4e5f6g | hotfix/session | commit | fix: session timeout | — |
| 3 | → | h7i8j9k | feature/login | commit | feat: add login form | — |
| 4 | → | l0m1n2o | feature/login | merge | Merge branch 'ui/button' into feature/login | ui/button → feature/login |
| 5 | → | p3q4r5s | ui/button | commit | style: update button color | — |
| 6 | → | t6u7v8w | ui/button | commit | style: fix padding | — |

> 說明：`d4e5f6g` 在 lookup table 中 → 所屬分支 = `hotfix/session`；`h7i8j9k` 不在 lookup table，最近更新 merge（`l0m1n2o`）target = `feature/login` → 所屬分支 = `feature/login`。

---

**精簡表格**（lookup table 中的 commits 折疊進對應 merge commit）：

| # | 方向 | Commit Hash | 所屬分支 | 類型 | Commit Message | Merge 資訊 | Commit Count |
|---|------|-------------|----------|------|----------------|------------|--------------|
| 1 | ← | a1b2c3d | hotfix/session | merge | Merge branch 'hotfix/session' into main | hotfix/session → main | 1 |
| 3 | → | h7i8j9k | feature/login | commit | feat: add login form | — | 1 |
| 4 | → | l0m1n2o | ui/button | merge | Merge branch 'ui/button' into feature/login | ui/button → feature/login | 2 |

> 說明：`d4e5f6g`（lookup: hotfix/session）折疊進 `a1b2c3d`，Count = 1；`p3q4r5s`、`t6u7v8w`（lookup: ui/button）折疊進 `l0m1n2o`，Count = 2；`h7i8j9k` 不在 lookup table → 單獨列出，Count = 1。Merge commit 的所屬分支填 source branch。
