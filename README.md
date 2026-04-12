# 🔄 aiswap

### The Intelligent Profile Switcher

**aiswap** is a utility that lets you instantly switch between different AI personalities and service configurations (Claude, Gemini, Mistral, OpenAI, etc.) without manually editing config files.

It is designed to be:

* **Invisible when it works**
* **Informative when it doesn’t**
* **Safe by default**

---

## 🚀 Quick Start

Once initialized, you can switch profiles using simple commands:

```bash
aiswap c
aiswap g
aiswap m
aiswap o
```

Or—more ergonomically—via aliases:

```bash
alpha
stargate
```

```text
✅ Switched: alpha → stargate
```

---

## ✨ Dynamic Alias System

Aliases are no longer hardcoded in your shell.

They are now:

* **Stored as data**
* **Editable at runtime**
* **Automatically injected into your shell**
* **Fully integrated** (Custom aliases appear natively in `aiswap list` and `status`)
* **Guaranteed to load** (Default profiles are always available, even on a fresh install)

This means:

* No `.bashrc` editing
* Minimal reload friction (instant with `aiswap alias rebuild`)
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

Aliases are automatically loaded:

* On shell startup (via `.bashrc`)
* Or instantly with `aiswap alias rebuild`

---

## 🛠️ Commands & Options

### Managing State

* **`aiswap status` / `aiswap -s`**
  Show the active profile.

* **`aiswap list` / `aiswap -l`**
  List all profiles (`*` = active).

* **`aiswap diff <id>` / `aiswap -d <id>`**
  Compare current config vs another profile.

---

### Setup & Editing

* **`aiswap init`**
  Initialize config directory and profiles.

* **`aiswap edit`**
  Open active config in your preferred editor
  (`code → subl → micro → nano → vim → vi`)

---

### Alias Control Plane

* **`aiswap alias list`**
* **`aiswap alias add <id> <name>`**
* **`aiswap alias remove <name>`**
* **`aiswap alias edit`**
* **`aiswap alias rebuild`**

---

### Help & Info

* **`aiswap help` / `aiswap -h`**
  Show full usage and command reference.

* **`aiswap version`**
  Show current version.

---

### Safety Options

* **`-n`, `--dry-run`**
  Strictly preview actions and log intended operations without mutating state.

* **`-v`, `--verbose`**
  Show detailed execution logs.

Example:

```bash
aiswap -n g
aiswap -v c
```

---

## 🛡️ Safety Features

**aiswap** is built to prevent state corruption and data loss.

### 1. Atomic Operations

All writes use `mktemp + mv` to ensure consistency.

### 2. Controlled State Persistence

Profile state is atomically swapped.
Explicit persistence guarantees may be expanded in future versions.

### 3. Cross-Platform Locking

Prevents concurrent swaps using a robust lock directory, featuring `mtime`-based stale lock detection compatible with both GNU and BSD `stat`.

### 4. Smart State Recovery (Fingerprinting)

If state tracking is lost but configs exist, aiswap uses file fingerprinting to deduce and restore the active profile.

### 5. Auto-Backup System

Unrecognized manual edits to `config.yaml` are never overwritten blindly. They are preserved in:

```
~/.config/aichat/backups/
```

### 6. Shell Inoculation

Core operations strictly use `command` to bypass interactive user aliases (like `alias mv='mv -i'`), ensuring reliable execution in heavily customized environments.

---

## 📂 Configuration Layout

```
~/.config/aichat/
├── config.yaml
├── c.config.yaml
├── g.config.yaml
├── m.config.yaml
├── o.config.yaml
├── aliases
├── current
└── backups/
```

---

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

```bash
if [[ $- == *i* ]]; then
    _aichat_swap alias rebuild 2>/dev/null
fi
```

---

## 🧩 Design Philosophy

| Layer    | Responsibility      |
| -------- | ------------------- |
| Profiles | Configuration state |
| Aliases  | User interface      |
| aiswap   | Orchestration       |

---

## ❤️ Built for aichat

Designed to pair with:

👉 [https://github.com/sigoden/aichat](https://github.com/sigoden/aichat)

---

## ⚠️ Disclaimer

Independent project. Not affiliated with aichat.

## 🧭 Project Status

**aiswap v1.2.6**

Stable for:

* Local atomic profile switching
* Alias-driven workflows
* Cross-platform execution (WSL/Arch/macOS)

Planned:

* Cross-machine sync
* Remote reconciliation
* Validation layer