---
name: vcs-helper
description: |
  Git 版控輔助工具集主入口。

  【主入口觸發詞】當使用者輸入以下任一詞彙，提示是否使用此工具集：
  版本控制、版控、VCS、git 工具、git 助手、git 管理、vcs-helper

  【子 skill 直接觸發詞】偵測到以下詞彙時，直接提示對應子 skill：
  - 比較分支 / 分支差異 / branch diff / 兩個分支差了什麼 / commit 差異
    → 提示使用 /vcs-helper:branch_commit_diff

  【直接呼叫格式】使用者輸入 /vcs-helper:<子功能名稱> 時直接執行，不顯示選單。

  ⚠️ 此 skill 僅由使用者主動觸發，Claude 不得自動執行。
---

# vcs-helper — Git 版控輔助工具集

---

## 觸發模式總覽

此 skill 有三種觸發模式，**三種皆為使用者主動觸發，Claude 不自動執行**：

| 模式 | 使用者輸入範例 | Claude 的行為 |
|------|--------------|--------------|
| **主入口** | 「版控」、「VCS」、「git 工具」 | 詢問是否使用工具集，顯示子 skill 選單 |
| **子 skill 提示** | 「比較分支差異」、「branch diff」 | 直接提示對應子 skill，詢問是否執行 |
| **直接呼叫** | `/vcs-helper:branch_commit_diff` | 直接讀取並執行對應子 skill，不顯示選單 |

---

## 模式一：主入口觸發

當偵測到主入口觸發詞時，詢問使用者：

```
偵測到版控相關需求，是否要使用 vcs-helper 工具集？

可用功能：
  /vcs-helper:branch_commit_diff  — 比較兩個分支的 commit 差異

請輸入指令，或告訴我您想做什麼。
```

---

## 模式二：子 skill 觸發詞提示

當偵測到子 skill 觸發詞（但使用者未使用 `/vcs-helper:` 格式），直接提示：

```
您的需求符合 /vcs-helper:branch_commit_diff（比較分支 commit 差異）。
是否要執行？
```

等待使用者確認後，讀取並執行對應子 skill 的 SKILL.md。

---

## 模式三：直接呼叫

使用者輸入 `/vcs-helper:<子功能名稱>` 時，直接查表執行：

| 指令 | 執行路徑 |
|------|---------|
| `/vcs-helper:branch_commit_diff` | `sub-skills/branch/branch_commit_diff/SKILL.md` |

讀取對應 SKILL.md，**立即開始執行，不顯示選單，不詢問確認**。

---

## 子 skill 索引

### 📁 branch/ — 分支相關

| 子 skill | 指令 | 觸發詞 |
|----------|------|--------|
| 比較兩分支 commit 差異 | `/vcs-helper:branch_commit_diff` | 比較分支、分支差異、branch diff、兩個分支差了什麼、commit 差異、哪些 commit 不同 |

### 📁 commit/ — commit 相關（待新增）

### 📁 tag/ — tag 與 release 相關（待新增）

---

## 全域核心原則

所有子 skill 執行前必須遵守 `shared/principles.md`：
- 所有輸出 100% 來自 git 指令實際執行結果
- 不猜測、不推斷、不補充、不美化
- git 錯誤原文顯示，立即停止

---

## 目錄結構

```
vcs-helper/
├── SKILL.md                              ← 本檔案（主入口 + router）
├── shared/
│   ├── principles.md                     ← 全域核心原則（所有子 skill 共用）
│   ├── scripts/
│   │   └── git_utils.sh                  ← 共用 bash helpers
│   └── templates/
│       └── output.md.tmpl                ← 統一 MD 輸出模板
└── sub-skills/
    ├── branch/
    │   └── branch_commit_diff/
    │       └── SKILL.md
```
