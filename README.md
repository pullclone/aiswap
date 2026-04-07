# 🔄 aiswap
### The Intelligent Profile Switcher

**aiswap** is a utility that lets you instantly switch between different AI personalities and service configurations (Claude, Gemini, Mistral, OpenAI, etc.) without manually editing config files.

It is designed to be:
- **Invisible when it works**
- **Informative when it doesn’t**
- **Safe by default**

---

## 🚀 Quick Start

Once initialized, you can switch profiles using simple commands:

```bash
aiswap c
aiswap g
aiswap m
aiswap o
````

Or—more ergonomically—via aliases:

```bash
alpha
stargate
```

> `✅ Switched: alpha → stargate`

---

## ✨ New: Dynamic Alias System

Aliases are no longer hardcoded in your shell.

They are now:

* **Stored as data**
* **Editable at runtime**
* **Automatically loaded into your shell**

This means:

* No `.bashrc` editing
* No reload friction
* Fully portable alias configs

---

## 🧠 Alias Management

### View aliases

```bash
aiswap alias list
```

### Add a new alias

```bash
aiswap alias add g fast
```

Now:

```bash
fast
```

### Remove an alias

```bash
aiswap alias remove fast
```

### Edit aliases manually

```bash
aiswap alias edit
```

### Reload aliases into current shell

```bash
aiswap alias rebuild
```

---

## 🛠️ Commands & Options

### Managing State

* **`aiswap status`**
  Show the active profile.

* **`aiswap list`**
  List all profiles (`*` = active).

* **`aiswap diff <id>`**
  Compare current config vs another profile.
  *Example:* `aiswap diff c`

---

### Setup & Editing

* **`aiswap init`**
  Initialize config directory and profiles.

* **`aiswap edit`**
  Open active config in your preferred editor
  (auto-detected: VS Code → Micro → Nano → Vim).

---

### Alias Control Plane

* **`aiswap alias list`**
* **`aiswap alias add <id> <name>`**
* **`aiswap alias remove <name>`**
* **`aiswap alias edit`**
* **`aiswap alias rebuild`**

---

### Safety Options

* **`-n`, `--dry-run`**
  Preview actions without applying changes.

* **`-v`, `--verbose`**
  Show detailed execution logs.

---

## 🛡️ Safety Features

**aiswap** is built to prevent state corruption and data loss.

### 1. Atomic Operations

All writes use `mktemp + mv` to ensure consistency.

### 2. Auto-Save

Modified configs are saved back to their profile before switching.

### 3. Locking

Prevents concurrent swaps using a lock directory with stale cleanup.

### 4. Smart Recovery

If state tracking is missing, aiswap fingerprints configs to recover identity.

### 5. Backup System

Unknown states are preserved in:

```

~/.config/aichat/backups/
```

---

## 📂 Configuration Layout

```

~/.config/aichat/
├── config.yaml          # Active config
├── c.config.yaml        # Claude profile
├── g.config.yaml        # Gemini profile
├── m.config.yaml        # Mistral profile
├── o.config.yaml        # OpenAI profile
├── aliases              # Alias definitions (NEW)
├── current              # Active profile tracker
└── backups/             # Safety snapshots

```

### Alias File Format

```

<profile_id> <alias_name>

```

Example:

```

g alpha
o stargate

```

---

## ⚙️ Shell Integration

Add this to your `.bashrc`:

```bash
if [[ $- == *i* ]]; then
    _aichat_swap alias rebuild
fi
```

This ensures aliases are automatically loaded every session.

---

## 🧩 Design Philosophy

**aiswap** separates concerns cleanly:

| Layer    | Responsibility      |
| -------- | ------------------- |
| Profiles | Configuration state |
| Aliases  | User interface      |
| aiswap   | Orchestration       |

This enables:

* Portable setups
* Declarative configuration
* Extensible workflows

---

## ❤️ Built for aichat

Designed to pair seamlessly with:

👉 [https://github.com/sigoden/aichat](https://github.com/sigoden/aichat)

**aiswap** respects native `aichat` config structure while adding:

* Fast profile switching
* Safe state management
* Flexible interface control

---

## ⚠️ Disclaimer

**aiswap** is an independent community project.
It is not affiliated with or endorsed by the creators of aichat.
