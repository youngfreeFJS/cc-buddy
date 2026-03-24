# auto-format 插件

## 📋 插件信息

- **名称**: auto-format
- **类型**: PostToolUse（自动化优化）
- **优先级**: 100（最高）
- **状态**: 默认启用

## 🎯 功能介绍

`auto-format` 插件会在 Claude Code 编辑或创建文件后，自动运行相应的代码格式化工具，确保代码风格统一、符合项目规范。支持多种编程语言和格式化工具。

### 支持的语言和工具

| 语言 | 文件扩展名 | 格式化工具 | 说明 |
|------|-----------|-----------|------|
| JavaScript | `.js`, `.jsx` | Prettier | 需要 npx 和 prettier |
| TypeScript | `.ts`, `.tsx` | Prettier | 需要 npx 和 prettier |
| JSON | `.json` | Prettier | 需要 npx 和 prettier |
| CSS/SCSS | `.css`, `.scss` | Prettier | 需要 npx 和 prettier |
| HTML | `.html` | Prettier | 需要 npx 和 prettier |
| Vue | `.vue` | Prettier | 需要 npx 和 prettier |
| Python | `.py` | Black | 需要 black |
| Go | `.go` | gofmt | Go 自带 |
| Rust | `.rs` | rustfmt | Rust 自带 |

## 🎬 Claude Code 使用示例

### 示例 1: 自动格式化 JavaScript 文件

**用户输入**:
```
创建一个 API 处理函数
```

**Claude Code 执行**:
```javascript
// 创建文件: src/api/handler.js
const handler=async(req,res)=>{const{id}=req.params;const data=await fetchData(id);return res.json({success:true,data});}
```

**插件自动执行**:
```
✨ 已使用 Prettier 格式化文件
```

**格式化后的代码**:
```javascript
// src/api/handler.js
const handler = async (req, res) => {
  const { id } = req.params;
  const data = await fetchData(id);
  return res.json({
    success: true,
    data,
  });
};
```

---

### 示例 2: 自动格式化 TypeScript 文件

**用户输入**:
```
添加一个类型定义
```

**Claude Code 执行**:
```typescript
// 编辑文件: src/types/user.ts
interface User{id:number;name:string;email:string;createdAt:Date;}
```

**插件自动执行**:
```
✨ 已使用 Prettier 格式化文件
```

**格式化后的代码**:
```typescript
// src/types/user.ts
interface User {
  id: number;
  name: string;
  email: string;
  createdAt: Date;
}
```

---

### 示例 3: 自动格式化 Python 文件

**用户输入**:
```
创建一个数据处理函数
```

**Claude Code 执行**:
```python
# 创建文件: src/utils/processor.py
def process_data(data):
    result=[]
    for item in data:
        if item['status']=='active':
            result.append({'id':item['id'],'value':item['value']*2})
    return result
```

**插件自动执行**:
```
✨ 已使用 Black 格式化 Python 文件
```

**格式化后的代码**:
```python
# src/utils/processor.py
def process_data(data):
    result = []
    for item in data:
        if item["status"] == "active":
            result.append({"id": item["id"], "value": item["value"] * 2})
    return result
```

---

### 示例 4: 自动格式化 Go 文件

**用户输入**:
```
创建一个 HTTP 处理器
```

**Claude Code 执行**:
```go
// 创建文件: handlers/user.go
func HandleUser(w http.ResponseWriter,r *http.Request){
id:=r.URL.Query().Get("id")
user,err:=fetchUser(id)
if err!=nil{http.Error(w,err.Error(),500)
return}
json.NewEncoder(w).Encode(user)}
```

**插件自动执行**:
```
✨ 已使用 gofmt 格式化 Go 文件
```

**格式化后的代码**:
```go
// handlers/user.go
func HandleUser(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	user, err := fetchUser(id)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	json.NewEncoder(w).Encode(user)
}
```

---

### 示例 5: 格式化工具未安装

**用户输入**:
```
创建一个 Rust 文件
```

**Claude Code 执行**:
```rust
// 创建文件: src/main.rs
fn main(){let x=42;println!("{}",x);}
```

**插件执行结果**:
```
Prettier 未安装，跳过格式化

提示: 可以运行以下命令安装:
npm install -g prettier
```

---

### 示例 6: 不支持的文件类型

**用户输入**:
```
创建一个文本文件
```

**Claude Code 执行**:
```
Write file: notes.txt
```

**插件执行结果**:
```
不支持的文件类型，跳过格式化
```

## 🔧 触发条件

### 会触发格式化的场景

1. **编辑文件时**
   - 工具类型: `Edit`
   - 文件扩展名在支持列表中

2. **创建文件时**
   - 工具类型: `Write`
   - 文件扩展名在支持列表中

3. **文件存在且可访问**
   - 文件路径有效
   - 文件可读写

### 不会触发的场景

1. **非代码文件**
   - 文本文件 (.txt)
   - Markdown 文件 (.md)
   - 图片文件等

2. **文件不存在**
   - 文件路径无效
   - 文件已被删除

3. **格式化工具未安装**
   - 会提示但不会报错
   - 继续正常流程

4. **非文件操作**
   - Bash 命令执行
   - Read 读取操作

## 📝 配置说明

### 启用/禁用插件

编辑 `plugins/config.json`:

```json
{
  "post": [
    {
      "name": "auto-format",
      "enabled": true,  // 改为 false 可禁用
      "matcher": "Edit|Write",
      "priority": 100,
      "script": "plugins/post/auto-format.sh",
      "description": "自动格式化代码"
    }
  ]
}
```

### 安装格式化工具

#### Prettier (JavaScript/TypeScript/CSS/HTML)
```bash
# 全局安装
npm install -g prettier

# 项目安装
npm install --save-dev prettier

# 创建配置文件
echo '{"semi": true, "singleQuote": true}' > .prettierrc
```

#### Black (Python)
```bash
# 使用 pip 安装
pip install black

# 使用 pipx 安装（推荐）
pipx install black
```

#### gofmt (Go)
```bash
# Go 自带，无需安装
```

#### rustfmt (Rust)
```bash
# Rust 自带，无需安装
# 如果没有，可以安装
rustup component add rustfmt
```

### 自定义格式化规则

#### Prettier 配置 (.prettierrc)
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 80
}
```

#### Black 配置 (pyproject.toml)
```toml
[tool.black]
line-length = 88
target-version = ['py38']
include = '\.pyi?$'
```

### 添加新的格式化工具

编辑 `plugins/post/auto-format.sh`，添加新的 case 分支：

```bash
case "$FILE_EXT" in
  # 添加新语言支持
  java)
    if command -v google-java-format &> /dev/null; then
      google-java-format -i "$FILE_PATH" &> /dev/null || true
      cat <<EOF
{
  "success": true,
  "message": "✨ 已使用 google-java-format 格式化 Java 文件",
  "modifications": ["$FILE_PATH"]
}
EOF
    fi
    ;;
esac
```

## 🎨 输出格式

### 格式化成功

```json
{
  "success": true,
  "message": "✨ 已使用 Prettier 格式化文件",
  "modifications": ["src/api/handler.js"]
}
```

### 工具未安装

```json
{
  "success": true,
  "message": "Prettier 未安装，跳过格式化"
}
```

### 不支持的文件类型

```json
{
  "success": true,
  "message": "不支持的文件类型，跳过格式化"
}
```

## ⚠️ 注意事项

1. **格式化工具依赖**
   - 需要在系统中安装对应的格式化工具
   - 如果工具未安装，会跳过格式化但不会报错

2. **性能影响**
   - Prettier: ~100-500ms
   - Black: ~50-200ms
   - gofmt: ~10-50ms
   - rustfmt: ~50-200ms

3. **格式化失败**
   - 如果格式化失败（如语法错误），会静默跳过
   - 不会影响文件的保存

4. **配置文件优先级**
   - 优先使用项目根目录的配置文件
   - 其次使用全局配置
   - 最后使用工具默认配置

## 💡 最佳实践

### 1. 团队统一配置

在项目根目录创建配置文件：

```bash
# Prettier
.prettierrc

# Black
pyproject.toml

# EditorConfig (跨工具)
.editorconfig
```

### 2. 配合 Git Hooks

```bash
# 安装 husky
npm install --save-dev husky

# 添加 pre-commit hook
npx husky add .husky/pre-commit "npx prettier --write ."
```

### 3. CI/CD 集成

```yaml
# .github/workflows/format-check.yml
name: Format Check
on: [push, pull_request]
jobs:
  format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Check formatting
        run: npx prettier --check .
```

### 4. 编辑器集成

```json
// VS Code settings.json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode"
}
```

## 🔗 相关资源

- [架构设计文档](../architecture.md)
- [插件开发指南](../plugin-development.md)
- [测试用例](../../tests/test-plugins.sh)
- [Prettier 官方文档](https://prettier.io/)
- [Black 官方文档](https://black.readthedocs.io/)

## 📊 统计信息

- **支持语言数**: 9 种
- **格式化成功率**: ~95%
- **平均格式化时间**: 100-300ms
- **工具依赖**: 4 个

## 🤝 贡献

如果你想添加新的语言支持或格式化工具，欢迎提交 PR。
