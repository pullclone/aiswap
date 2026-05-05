# shellcheck shell=bash
###############################################################################
# _aichat_swap v1.2.8
#
# Standalone aichat profile switcher. Source this file from .bashrc,
# .bash_profile, or another Bash startup file.
###############################################################################

_aichat_swap() {
	local VERSION="1.2.8"

	local BASE_DIR="${AICHAT_CONF_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/aichat}"
	local DIR="$BASE_DIR"
	local BACKUP_DIR="$DIR/backups"
	local LOCK_DIR="$DIR/.swap.lock.d"
	local CURRENT_FILE="$DIR/current"
	local ALIAS_FILE="$DIR/aliases"

	local IDS=(c g m o)
	local NAMES=(altostrat alpha lechat stargate)

	local DRY_RUN=false
	local VERBOSE=false
	local TMPFILE=""
	local HAVE_LOCK=false

	_aiswap_load_profiles() {
		local new_ids=() new_names=()
		local i j found id name

		for i in "${!IDS[@]}"; do
			new_ids+=("${IDS[$i]}")
			new_names+=("${NAMES[$i]}")
		done

		if [[ -f "$ALIAS_FILE" ]]; then
			while read -r id name _; do
				[[ -z "$id" || -z "$name" || "$id" == \#* ]] && continue
				found=false
				for j in "${!new_ids[@]}"; do
					if [[ "${new_ids[$j]}" == "$id" ]]; then
						new_names[j]="$name"
						found=true
						break
					fi
				done
				if ! $found; then
					new_ids+=("$id")
					new_names+=("$name")
				fi
			done <"$ALIAS_FILE"
		fi

		IDS=("${new_ids[@]}")
		NAMES=("${new_names[@]}")
	}

	_aiswap_msg() {
		local type="$1"
		shift
		local color=0 out=1 prefix=""
		case "$type" in
		err)
			color=1
			out=2
			prefix="error: "
			;;
		warn)
			color=3
			out=2
			prefix="warning: "
			;;
		ok) color=2 ;;
		info) color=4 ;;
		dry)
			color=5
			prefix="[dry-run] "
			;;
		esac

		if [[ -t $out ]] && command -v tput >/dev/null 2>&1; then
			command printf "%b\n" "$(command tput setaf "$color")${prefix}$*$(command tput sgr0)" >&"$out"
		else
			command printf "%s\n" "${prefix}$*" >&"$out"
		fi
	}

	_aiswap_verbose() {
		$VERBOSE && _aiswap_msg info "$@"
		return 0
	}

	_aiswap_get_editor() {
		if [[ -n "${EDITOR:-}" ]]; then
			command printf "%s\n" "$EDITOR"
			return 0
		fi

		local editors=(code subl micro nano vim vi)
		local ed
		for ed in "${editors[@]}"; do
			if command -v "$ed" >/dev/null 2>&1; then
				command printf "%s\n" "$ed"
				return 0
			fi
		done

		if command -v xdg-open >/dev/null 2>&1; then
			command printf "%s\n" "xdg-open"
			return 0
		fi
		if command -v open >/dev/null 2>&1; then
			command printf "%s\n" "open"
			return 0
		fi

		command printf "%s\n" "cat"
	}

	_aiswap_get_name() {
		local target="$1" i
		for i in "${!IDS[@]}"; do
			if [[ "${IDS[$i]}" == "$target" ]]; then
				command printf "%s\n" "${NAMES[$i]}"
				return 0
			fi
		done
		command printf "%s\n" "unknown"
	}

	_aiswap_is_known_id() {
		local target="$1" i
		for i in "${!IDS[@]}"; do
			[[ "${IDS[$i]}" == "$target" ]] && return 0
		done
		return 1
	}

	_aiswap_valid_id() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]; }
	_aiswap_valid_alias_name() { [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]]; }

	_aiswap_read_current() {
		[[ -f "$CURRENT_FILE" ]] || return 0
		command head -n 1 "$CURRENT_FILE" 2>/dev/null | command tr -d '\r\n'
	}

	_aiswap_write_current() {
		command printf "%s\n" "$1" >"$CURRENT_FILE"
	}

	_aiswap_alias_list() {
		[[ -f "$ALIAS_FILE" ]] && command cat "$ALIAS_FILE"
		return 0
	}

	_aiswap_alias_write() {
		command mkdir -p "$DIR" 2>/dev/null || return 1
		local tmp
		tmp=$(command mktemp "$DIR/.aliases.tmp.XXXXXX") || return 1
		command cat >"$tmp" || {
			command rm -f "$tmp" 2>/dev/null
			return 1
		}
		command mv -f "$tmp" "$ALIAS_FILE"
	}

	_aiswap_rebuild_aliases() {
		alias aiswap="_aichat_swap"
		local i
		for i in "${!IDS[@]}"; do
			# shellcheck disable=SC2139
			alias "${NAMES[$i]}"="_aichat_swap ${IDS[$i]}" 2>/dev/null || true
		done
	}

	_aiswap_lock_mtime() {
		if command stat -c %Y "$LOCK_DIR" >/dev/null 2>&1; then
			command stat -c %Y "$LOCK_DIR"
		elif command stat -f %m "$LOCK_DIR" >/dev/null 2>&1; then
			command stat -f %m "$LOCK_DIR"
		else
			command printf "%s\n" 0
		fi
	}

	_aiswap_acquire_lock() {
		command mkdir -p "$DIR" 2>/dev/null || return 1
		local retries=0 max=6 stale=30 now mtime
		while ((retries < max)); do
			if command mkdir "$LOCK_DIR" 2>/dev/null; then
				return 0
			fi

			now=$(command date +%s)
			mtime=$(_aiswap_lock_mtime)
			if [[ "$mtime" =~ ^[0-9]+$ ]] && ((mtime > 0 && now - mtime > stale)); then
				_aiswap_msg warn "stale lock detected; reclaiming"
				command rmdir "$LOCK_DIR" 2>/dev/null || true
				continue
			fi

			command sleep 1
			((retries++))
		done
		return 1
	}

	_aiswap_cleanup() {
		[[ -n "$TMPFILE" && -f "$TMPFILE" ]] && command rm -f "$TMPFILE" 2>/dev/null
		if $HAVE_LOCK; then
			command rmdir "$LOCK_DIR" 2>/dev/null || true
			HAVE_LOCK=false
		fi
		trap - INT TERM 2>/dev/null || true
	}

	_aiswap_show_help() {
		command cat <<EOF
aiswap v$VERSION

Usage:
  aiswap [options] <command|profile_id>

Commands:
  list, ls, -l                 List profiles
  status, stat, -s             Show active profile
  diff <id>, -d <id>           Diff active config against a profile
  edit                         Edit active config
  init                         Create config and backup directories
  alias list                   List custom aliases
  alias add <id> <name>        Add or override a profile alias
  alias remove <name>          Remove a profile alias
  alias edit                   Edit the alias file
  alias rebuild                Rebuild shell aliases
  help, -h                     Show help

Options:
  -n, --dry-run                Preview a profile switch without changing files
  -v, --verbose                Print extra operation detail
EOF
	}

	_aiswap_load_profiles

	local args=()
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-n | --dry-run) DRY_RUN=true ;;
		-v | --verbose) VERBOSE=true ;;
		-h) args+=("help") ;;
		-l) args+=("list") ;;
		-s) args+=("status") ;;
		-d) args+=("diff") ;;
		*) args+=("$1") ;;
		esac
		shift
	done
	set -- "${args[@]}"

	local cmd="${1:-status}"
	cmd=$(command printf "%s" "$cmd" | command tr '[:upper:]' '[:lower:]')

	case "$cmd" in
	ls) cmd="list" ;;
	stat) cmd="status" ;;
	esac

	if [[ "$cmd" == "alias" ]]; then
		case "${2:-list}" in
		list)
			_aiswap_alias_list
			;;
		add)
			local alias_id="${3:-}" alias_name="${4:-}"
			[[ -z "$alias_id" || -z "$alias_name" ]] && {
				_aiswap_msg err "usage: alias add <profile_id> <alias_name>"
				return 1
			}
			_aiswap_valid_id "$alias_id" || {
				_aiswap_msg err "invalid profile id: $alias_id"
				return 1
			}
			_aiswap_valid_alias_name "$alias_name" || {
				_aiswap_msg err "invalid alias name: $alias_name"
				return 1
			}
			{
				_aiswap_alias_list
				command printf "%s %s\n" "$alias_id" "$alias_name"
			} | _aiswap_alias_write || return 1
			_aiswap_msg ok "alias added: $alias_name -> $alias_id"
			;;
		remove)
			local alias_name="${3:-}"
			[[ -z "$alias_name" ]] && {
				_aiswap_msg err "usage: alias remove <alias_name>"
				return 1
			}
			_aiswap_valid_alias_name "$alias_name" || {
				_aiswap_msg err "invalid alias name: $alias_name"
				return 1
			}
			if [[ -f "$ALIAS_FILE" ]]; then
				command awk -v name="$alias_name" '$2 != name' "$ALIAS_FILE" | _aiswap_alias_write || return 1
			fi
			unalias "$alias_name" 2>/dev/null || true
			_aiswap_msg ok "alias removed: $alias_name"
			;;
		edit)
			"$(_aiswap_get_editor)" "$ALIAS_FILE"
			;;
		rebuild)
			_aiswap_rebuild_aliases
			;;
		*)
			_aiswap_msg err "usage: alias [list|add|remove|edit|rebuild]"
			return 1
			;;
		esac
		return 0
	fi

	case "$cmd" in
	help)
		_aiswap_show_help
		return 0
		;;
	list)
		local current="" i mark
		current=$(_aiswap_read_current)
		for i in "${!IDS[@]}"; do
			mark=" "
			[[ "${IDS[$i]}" == "$current" ]] && mark="*"
			command printf "%s [%s] %s\n" "$mark" "${IDS[$i]}" "${NAMES[$i]}"
		done
		return 0
		;;
	status)
		local current=""
		current=$(_aiswap_read_current)
		[[ -n "$current" ]] && _aiswap_msg info "Active: $(_aiswap_get_name "$current")"
		return 0
		;;
	edit)
		"$(_aiswap_get_editor)" "$DIR/config.yaml"
		return 0
		;;
	diff)
		local target_id="${2:-}"
		[[ -z "$target_id" ]] && {
			_aiswap_msg err "usage: diff <profile_id>"
			return 1
		}
		command -v diff >/dev/null 2>&1 || {
			_aiswap_msg err "'diff' command not found"
			return 1
		}

		local diff_opts=(-u)
		if command diff --color=auto /dev/null /dev/null >/dev/null 2>&1; then
			diff_opts+=("--color=auto")
		fi

		[[ -f "$DIR/$target_id.config.yaml" ]] || {
			_aiswap_msg err "profile '$target_id' not found"
			return 1
		}
		command diff "${diff_opts[@]}" "$DIR/config.yaml" "$DIR/$target_id.config.yaml"
		return $?
		;;
	init)
		command mkdir -p "$DIR" "$BACKUP_DIR"
		_aiswap_msg ok "initialization complete; no profile files were created"
		return 0
		;;
	esac

	local target="$cmd"
	local current=""
	current=$(_aiswap_read_current)

	if ! _aiswap_is_known_id "$target"; then
		_aiswap_msg err "unknown profile or command: '$target'"
		_aiswap_msg info "use 'aiswap list' to see profiles"
		return 1
	fi

	local src="$DIR/$target.config.yaml"
	if [[ ! -f "$src" ]]; then
		_aiswap_msg err "missing profile: $src"
		return 1
	fi

	if [[ -n "$current" ]] && ! _aiswap_is_known_id "$current"; then
		_aiswap_msg warn "current marker '$current' is not a known profile"
		current=""
	fi

	if [[ "$target" == "$current" ]]; then
		_aiswap_msg ok "profile [$target] already active"
		return 0
	fi

	if $DRY_RUN; then
		_aiswap_msg dry "would lock, save current state, and swap to $(_aiswap_get_name "$target") ($target)"
		return 0
	fi

	_aiswap_acquire_lock || {
		_aiswap_msg err "lock failed; another swap may be running"
		return 1
	}
	HAVE_LOCK=true
	trap '_aiswap_cleanup; return 130' INT TERM

	_aiswap_verbose "lock acquired: $LOCK_DIR"

	if [[ -z "$current" && -f "$DIR/config.yaml" ]]; then
		_aiswap_msg warn "unknown current state; fingerprinting active config"
		local id match_id=""
		for id in "${IDS[@]}"; do
			if command cmp -s "$DIR/config.yaml" "$DIR/$id.config.yaml" 2>/dev/null; then
				match_id="$id"
				break
			fi
		done

		if [[ -n "$match_id" ]]; then
			current="$match_id"
			_aiswap_write_current "$current"
			_aiswap_verbose "matched active config to profile: $current"
		else
			local ts
			ts=$(command date +%Y%m%d_%H%M%S)
			_aiswap_msg warn "no profile match found; backing up active config"
			command mkdir -p "$BACKUP_DIR" 2>/dev/null
			command cp -p "$DIR/config.yaml" "$BACKUP_DIR/unknown_$ts.yaml" 2>/dev/null
			command find "$BACKUP_DIR" -type f -mtime +7 -delete 2>/dev/null || true
		fi
	fi

	if [[ -n "$current" ]]; then
		local storage_file="$DIR/$current.config.yaml"
		if ! command cmp -s "$DIR/config.yaml" "$storage_file" 2>/dev/null; then
			_aiswap_verbose "saving active config to profile: $current"
			command cp -p "$DIR/config.yaml" "$storage_file" 2>/dev/null
		fi
	fi

	if [[ ! -s "$src" && -s "$DIR/config.yaml" ]]; then
		_aiswap_msg warn "target profile [$target] is empty; adopting active config data"
		command cp -p "$DIR/config.yaml" "$src" 2>/dev/null
	fi

	TMPFILE=$(command mktemp "$DIR/.tmp.XXXXXX") || {
		_aiswap_msg err "failed to create temp file"
		_aiswap_cleanup
		return 1
	}

	command cp -p "$src" "$TMPFILE" || {
		_aiswap_msg err "failed to copy profile to temp file"
		_aiswap_cleanup
		return 1
	}
	command mv -f "$TMPFILE" "$DIR/config.yaml" || {
		_aiswap_msg err "failed to move temp config into place"
		_aiswap_cleanup
		return 1
	}
	TMPFILE=""
	_aiswap_write_current "$target"

	_aiswap_msg ok "switched to $(_aiswap_get_name "$target")"
	_aiswap_cleanup
	return 0
}

function aiswap {
	_aichat_swap "$@"
}

alias aiswap='_aichat_swap'

if [[ $- == *i* ]]; then
	_aichat_swap alias rebuild 2>/dev/null || true
fi
