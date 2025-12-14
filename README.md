
# 🔄 aiswap
### The Intelligent Profile Switcher

**aiswap** is a utility that lets you instantly switch between different AI personalities and service configurations (like Claude, Gemini, Mistral, and OpenAI) without ever touching a config file manually. It is designed to be invisible when it works, and informative if something goes wrong.

---

## 🚀 Quick Start

Once installed, you don't even need to remember the command `aiswap`. You can use the friendly aliases assigned to your profiles:

| Command | Profile | Description |
| :--- | :--- | :--- |
| **`altostrat`** | `c` | Switches to the **Claude** profile. |
| **`alpha`** | `g` | Switches to the **Gemini** profile. |
| **`lechat`** | `m` | Switches to the **Mistral** profile. |
| **`stargate`** | `o` | Switches to the **OpenAI** profile. |

Just type the alias and hit enter.
> `✅ Switched: alpha → stargate`

---

## 🛠️ Commands & Options

You can do more than just switch profiles. The main command `aiswap` (or `_aichat_swap`) accepts several helpful sub-commands.

### Managing Your State
*   **`aiswap status`**
    Tells you exactly which profile is currently active.
*   **`aiswap list`**
    Shows all available profiles and marks the active one with a `*`.
*   **`aiswap diff <id>`**
    Compare your *current* settings against another profile to see what changed.
    *Example:* `aiswap diff c` (Compare current vs Altostrat)

### Setup & Editing
*   **`aiswap edit`**
    Opens the currently active configuration in your favorite editor. It automatically finds the best editor available (VS Code, Micro, Nano, or Vim).
*   **`aiswap init`**
    Run this once to automatically create all necessary folders and skeleton files.

### Safety Options
*   **`-n` / `--dry-run`**
    Want to see what *would* happen without actually changing anything?
    *Example:* `alpha -n`
*   **`-v` / `--verbose`**
    Show detailed logs of every file move and copy operation.

---

## 🛡️ Safety Features

**aiswap** is built to prevent data loss.

1.  **Auto-Save:** Before switching, if you made changes to your current config, they are automatically saved to that profile's storage.
2.  **Conflict Prevention:** If you run the command in two terminals at the same time, one will wait for the other to finish.
3.  **Smart Recovery:** If you manually delete the tracking file, **aiswap** scans your current config, compares it against your saved profiles, and figures out who you are automatically.
4.  **Backups:** If your current configuration doesn't match *anything* known, it is backed up to a `backups/` folder before a new profile is loaded.

---

## 📂 Configuration

Your files live here:
> `~/.config/aichat/` (or your XDG config path)

*   `config.yaml` (The active file used by the program)
*   `c.config.yaml` (Stored Claude profile)
*   `g.config.yaml` (Stored Gemini profile)
*   ...and so on.

---

## ❤️ Built for aichat

This tool is designed to be the perfect companion for **[aichat](https://github.com/sigoden/aichat)**, optimizing your workflow by allowing fluid transitions between different AI models and system prompts. It respects `aichat`'s native file structure to provide the best possible experience.

*Disclaimer: **aiswap** is an independent community project created to enhance productivity. It is not affiliated with, associated with, or endorsed by the creators of aichat.*
