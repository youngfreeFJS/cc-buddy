# auto-format Plugin

## 📋 Plugin Information

- **Name**: auto-format
- **Type**: PostToolUse (Automation Optimization)
- **Priority**: 100 (Highest)
- **Status**: Enabled by Default

## 🎯 Feature Overview

The `auto-format` plugin automatically runs the corresponding code formatting tools after Claude Code edits or creates files, ensuring consistent code style and compliance with project standards. Supports multiple programming languages and formatting tools.

### Supported Languages and Tools

| Language | File Extensions | Formatting Tool | Notes |
|----------|----------------|-----------------|-------|
| JavaScript | `.js`, `.jsx` | Prettier | Requires npx and prettier |
| TypeScript | `.ts`, `.tsx` | Prettier | Requires npx and prettier |
| JSON | `.json` | Prettier | Requires npx and prettier |
| CSS/SCSS | `.css`, `.scss` | Prettier | Requires npx and prettier |
| HTML | `.html` | Prettier | Requires npx and prettier |
| Vue | `.vue` | Prettier | Requires npx and prettier |
| Python | `.py` | Black | Requires black |
| Go | `.go` | gofmt | Built-in with Go |
| Rust | `.rs` | rustfmt | Built-in with Rust |

## 🎬 Claude Code Usage Examples

### Example 1: Automatically Format JavaScript File

**User Input**:
```
Create an API handler function
```

**Claude Code Executes**:
```javascript
// Create file: src/api/handler.js
const handler=async(req,res)=>{const{id}=req.params;const data=await fetchData(id);return res.json({success:true,data});}
```

**Plugin Automatically Executes**:
```
✨ File formatted with Prettier
```

**Formatted Code**:
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

### Example 2: Automatically Format TypeScript File

**User Input**:
```
Add a type definition
```

**Claude Code Executes**:
```typescript
// Edit file: src/types/user.ts
interface User{id:number;name:string;email:string;createdAt:Date;}
```

**Plugin Automatically Executes**:
```
✨ File formatted with Prettier
```

**Formatted Code**:
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

### Example 3: Automatically Format Python File

**User Input**:
```
Create a data processing function
```

**Claude Code Executes**:
```python
# Create file: src/utils/processor.py
def process_data(data):
    result=[]
    for item in data:
        if item['status']=='active':
            result.append({'id':item['id'],'value':item['value']*2})
    return result
```

**Plugin Automatically Executes**:
```
✨ Python file formatted with Black
```

**Formatted Code**:
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

### Example 4: Automatically Format Go File

**User Input**:
```
Create an HTTP handler
```

**Claude Code Executes**:
```go
// Create file: handlers/user.go
func HandleUser(w http.ResponseWriter,r *http.Request){
id:=r.URL.Query().Get("id")
user,err:=fetchUser(id)
if err!=nil{http.Error(w,err.Error(),500)
return}
json.NewEncoder(w).Encode(user)}
```

**Plugin Automatically Executes**:
```
✨ Go file formatted with gofmt
```

**Formatted Code**:
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

### Example 5: Formatting Tool Not Installed

**User Input**:
```
Create a Rust file
```

**Claude Code Executes**:
```rust
// Create file: src/main.rs
fn main(){let x=42;println!("{}",x);}
```

**Plugin Execution Result**:
```
Prettier not installed, skipping formatting

Hint: You can run the following command to install:
npm install -g prettier
```

---

### Example 6: Unsupported File Type

**User Input**:
```
Create a text file
```

**Claude Code Executes**:
```
Write file: notes.txt
```

**Plugin Execution Result**:
```
Unsupported file type, skipping formatting
```

## 🔧 Trigger Conditions

### Scenarios That Trigger Formatting

1. **When Editing Files**
   - Tool type: `Edit`
   - File extension is in the supported list

2. **When Creating Files**
   - Tool type: `Write`
   - File extension is in the supported list

3. **File Exists and is Accessible**
   - File path is valid
   - File is readable and writable

### Scenarios That Won't Trigger

1. **Non-Code Files**
   - Text files (.txt)
   - Markdown files (.md)
   - Image files, etc.

2. **File Doesn't Exist**
   - File path is invalid
   - File has been deleted

3. **Formatting Tool Not Installed**
   - Will prompt but won't error
   - Continues normal flow

4. **Non-File Operations**
   - Bash command execution
   - Read operations

## 📝 Configuration Instructions

### Enable/Disable Plugin

Edit `plugins/config.json`:

```json
{
  "post": [
    {
      "name": "auto-format",
      "enabled": true,  // Change to false to disable
      "matcher": "Edit|Write",
      "priority": 100,
      "script": "plugins/post/auto-format.sh",
      "description": "Automatically format code"
    }
  ]
}
```

### Install Formatting Tools

#### Prettier (JavaScript/TypeScript/CSS/HTML)
```bash
# Global installation
npm install -g prettier

# Project installation
npm install --save-dev prettier

# Create configuration file
echo '{"semi": true, "singleQuote": true}' > .prettierrc
```

#### Black (Python)
```bash
# Install using pip
pip install black

# Install using pipx (recommended)
pipx install black
```

#### gofmt (Go)
```bash
# Built-in with Go, no installation needed
```

#### rustfmt (Rust)
```bash
# Built-in with Rust, no installation needed
# If missing, you can install
rustup component add rustfmt
```

### Customize Formatting Rules

#### Prettier Configuration (.prettierrc)
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 80
}
```

#### Black Configuration (pyproject.toml)
```toml
[tool.black]
line-length = 88
target-version = ['py38']
include = '\.pyi?$'
```

### Add New Formatting Tools

Edit `plugins/post/auto-format.sh`, add a new case branch:

```bash
case "$FILE_EXT" in
  # Add new language support
  java)
    if command -v google-java-format &> /dev/null; then
      google-java-format -i "$FILE_PATH" &> /dev/null || true
      cat <<EOF
{
  "success": true,
  "message": "✨ Java file formatted with google-java-format",
  "modifications": ["$FILE_PATH"]
}
EOF
    fi
    ;;
esac
```

## 🎨 Output Format

### Formatting Successful

```json
{
  "success": true,
  "message": "✨ File formatted with Prettier",
  "modifications": ["src/api/handler.js"]
}
```

### Tool Not Installed

```json
{
  "success": true,
  "message": "Prettier not installed, skipping formatting"
}
```

### Unsupported File Type

```json
{
  "success": true,
  "message": "Unsupported file type, skipping formatting"
}
```

## ⚠️ Important Notes

1. **Formatting Tool Dependencies**
   - Need to install the corresponding formatting tool in the system
   - If the tool is not installed, formatting will be skipped without errors

2. **Performance Impact**
   - Prettier: ~100-500ms
   - Black: ~50-200ms
   - gofmt: ~10-50ms
   - rustfmt: ~50-200ms

3. **Formatting Failure**
   - If formatting fails (e.g., syntax error), it will be silently skipped
   - Won't affect file saving

4. **Configuration File Priority**
   - Prioritize configuration file in project root directory
   - Next, use global configuration
   - Finally, use tool default configuration

## 💡 Best Practices

### 1. Team Unified Configuration

Create configuration files in the project root directory:

```bash
# Prettier
.prettierrc

# Black
pyproject.toml

# EditorConfig (cross-tool)
.editorconfig
```

### 2. Integrate with Git Hooks

```bash
# Install husky
npm install --save-dev husky

# Add pre-commit hook
npx husky add .husky/pre-commit "npx prettier --write ."
```

### 3. CI/CD Integration

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

### 4. Editor Integration

```json
// VS Code settings.json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode"
}
```

## 🔗 Related Resources

- [Architecture Design Document](../architecture.md)
- [Plugin Development Guide](../plugin-development.md)
- [Test Cases](../../tests/test-plugins.sh)
- [Prettier Official Documentation](https://prettier.io/)
- [Black Official Documentation](https://black.readthedocs.io/)

## 📊 Statistics

- **Number of Supported Languages**: 9
- **Formatting Success Rate**: ~95%
- **Average Formatting Time**: 100-300ms
- **Tool Dependencies**: 4

## 🤝 Contributing

If you want to add new language support or formatting tools, you're welcome to submit a PR.
