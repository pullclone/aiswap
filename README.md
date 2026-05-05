# aiswap

`aiswap` is a standalone Bash utility for switching `aichat` config profiles without editing `config.yaml` by hand.

The implementation is sourceable from `.bashrc`, `.bash_profile`, or another shell file and targets broad Bash compatibility across Linux, WSL, macOS, and BSD-style systems where practical.

## Install

Copy or clone this repo, then source `aiswap.sh` from your Bash startup file:

```bash
# ~/.bashrc or ~/.bash_profile
source /path/to/aiswap/aiswap.sh
```

Reload the shell:

```bash
source ~/.bashrc
```

The file defines:

```bash
_aichat_swap
alias aiswap='_aichat_swap'
```

It also defines an `aiswap` function so non-interactive Bash scripts can call `aiswap` even when alias expansion is disabled.

## Config Directory

By default, aiswap uses:

```bash
${AICHAT_CONF_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/aichat}
```

Files live under that directory:

```text
config.yaml              active aichat config
current                  current profile marker
backups/                 unknown-state backups
.swap.lock.d/            transient lock directory
aliases                  optional custom alias data
<id>.config.yaml         stored profile config
```

`aiswap init` creates only the config directory and `backups/`. It does not create empty `config.yaml` or empty profile files.

## Default Profiles

```text
c -> altostrat
g -> alpha
m -> lechat
o -> stargate
```

Create the profile files you actually use:

```bash
aiswap init
cp ~/.config/aichat/config.yaml ~/.config/aichat/c.config.yaml
cp ~/.config/aichat/config.yaml ~/.config/aichat/g.config.yaml
```

Then switch:

```bash
aiswap c
aiswap g
```

## Commands

```text
aiswap list
aiswap ls
aiswap -l

aiswap status
aiswap stat
aiswap -s

aiswap diff <id>
aiswap -d <id>

aiswap edit
aiswap init

aiswap alias list
aiswap alias add <profile_id> <alias_name>
aiswap alias remove <alias_name>
aiswap alias edit
aiswap alias rebuild

aiswap help
aiswap -h

aiswap -n <id>
aiswap --dry-run <id>
aiswap -v <id>
aiswap --verbose <id>
```

## Aliases

Custom aliases are stored as data in:

```text
${AICHAT_CONF_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/aichat}/aliases
```

Format:

```text
<profile_id> <alias_name>
```

Example:

```bash
aiswap alias add g fast
aiswap alias rebuild
fast
```

Alias loading always starts with the defaults, then merges the alias file. Existing profile ids are overridden by entries in the file and new ids are added.

Validation rules:

```text
profile id:  ^[A-Za-z0-9][A-Za-z0-9_.-]*$
alias name:  ^[A-Za-z_][A-Za-z0-9_-]*$
```

## Safety Behavior

aiswap is hardened for interactive shells that define aliases such as `cp -i`, `cat=bat`, or `grep=rg`; internal file operations use `command` to avoid those aliases.

Profile switching uses a lock directory created with `mkdir`, retries briefly, and reclaims stale locks using GNU `stat -c %Y` or BSD `stat -f %m`.

When the current marker is missing or invalid, aiswap fingerprints the active `config.yaml` against known profile files with `cmp`. If no match is found, it backs up the active config to `backups/unknown_<timestamp>.yaml` and prunes backups older than seven days.

Before switching away from a known current profile, changed active config is saved back to `<current>.config.yaml`. The target profile is copied to a temporary file inside the config directory, moved into `config.yaml`, and then the current marker is updated.

If the target profile file is missing, switching fails. If the target profile file exists but is empty while the active config is non-empty, aiswap adopts the active config into that target profile before swapping.

## Validation

Run the standalone validator:

```bash
bash scripts/validate.sh
```

The validator uses a temporary `AICHAT_CONF_DIR` and does not touch the real `~/.config/aichat`.
