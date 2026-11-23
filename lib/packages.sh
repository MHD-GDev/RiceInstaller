#!/usr/bin/env bash
#
# RiceInstaller package planner.
#
# Resolve the complete package set before installing anything:
#   - treat installed packages and virtual providers as already satisfied;
#   - query package metadata in one batch;
#   - permit replacements declared by official Arch repositories;
#   - never auto-remove a conflicting AUR/custom-repository package;
#   - install official, custom-repository, and AUR packages in separate transactions.
#
# No --overwrite is used. File conflicts remain pacman's responsibility.

RI_PACKAGE_REPORT="${RI_PACKAGE_REPORT:-$HOME/missing_apps.txt}"

ri_package_report_init() {
    mkdir -p "$(dirname "$RI_PACKAGE_REPORT")"
    if [[ ! -f $RI_PACKAGE_REPORT ]]; then
        printf '# RiceInstaller package report (%s)\n' "$(date --iso-8601=seconds)" >"$RI_PACKAGE_REPORT"
    fi
}

ri_package_record() {
    local label="$1" package="$2" reason="$3"
    ri_package_report_init
    printf '[%s] %s: %s\n' "$label" "$package" "$reason" >>"$RI_PACKAGE_REPORT"
}

ri_package_name_from_spec() {
    local spec="$1"
    spec="${spec##*/}"
    spec="${spec%%[<=>]*}"
    printf '%s' "$spec"
}

ri_package_list_has() {
    local wanted="$1" list="$2" item
    local -a items=()
    read -r -a items <<<"$list"
    for item in "${items[@]}"; do
        [[ "$(ri_package_name_from_spec "$item")" == "$wanted" ]] && return 0
    done
    return 1
}


# Convert pacman -Qi output into installed package/conflict TSV data. This
# catches one-sided Conflicts declarations that are absent from the incoming
# package metadata.
ri_package_parse_installed_info() {
    local source="$1" destination="$2"
    awk '
        BEGIN { RS = ""; FS = "\n"; OFS = "\t" }
        {
            name = conflicts = ""
            for (i = 1; i <= NF; i++) {
                line = $i
                colon = index(line, ":")
                if (!colon) continue
                key = substr(line, 1, colon - 1)
                value = substr(line, colon + 1)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
                sub(/^[[:space:]]+/, "", value)
                sub(/[[:space:]]+$/, "", value)
                if (key == "Name") name = value
                else if (key == "Conflicts With") conflicts = value
            }
            if (name != "") print name, conflicts
        }
    ' "$source" >"$destination"
}

ri_package_is_official_repo() {
    case "$1" in
        core|extra|multilib) return 0 ;;
        *) return 1 ;;
    esac
}

# Convert paru -Si output to a stable TSV format.
ri_package_parse_sync_info() {
    local source="$1" destination="$2"
    awk '
        BEGIN { RS = ""; FS = "\n"; OFS = "\t" }
        {
            name = repo = conflicts = replaces = provides = ""
            for (i = 1; i <= NF; i++) {
                line = $i
                colon = index(line, ":")
                if (!colon) continue
                key = substr(line, 1, colon - 1)
                value = substr(line, colon + 1)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
                sub(/^[[:space:]]+/, "", value)
                sub(/[[:space:]]+$/, "", value)
                if (key == "Name") name = value
                else if (key == "Repository") repo = value
                else if (key == "Conflicts With") conflicts = value
                else if (key == "Replaces") replaces = value
                else if (key == "Provides") provides = value
            }
            if (name != "") print name, repo, conflicts, replaces, provides
        }
    ' "$source" >"$destination"
}

# Enable multilib only when a selected package group actually needs it.
# The original pacman.conf is preserved before changing anything.
ri_enable_multilib() {
    local conf="${RI_PACMAN_CONF:-/etc/pacman.conf}"
    local backup stamp

    pacman-conf --repo-list 2>/dev/null | grep -qx 'multilib' && return 0
    [[ -r $conf ]] || {
        err "Cannot read $conf; multilib cannot be enabled."
        return 1
    }

    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="$HOME/.local/share/RiceInstaller/backups/system/pacman.conf.$stamp"
    mkdir -p "$(dirname "$backup")"
    info "Enabling the official multilib repository for 32-bit gaming packages..."
    sudo cp -a -- "$conf" "$backup" || {
        err "Could not back up pacman.conf; leaving it unchanged."
        return 1
    }

    if ! sudo python3 - "$conf" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
lines = path.read_text().splitlines()
found = False

for index, line in enumerate(lines):
    commented_header = re.match(r"^\\s*#\\s*\\[\\s*multilib\\s*\\]\\s*$", line)
    active_header = re.match(r"^\\s*\\[\\s*multilib\\s*\\]\\s*$", line)
    if commented_header or active_header:
        lines[index] = "[multilib]"
        found = True
        include_found = False
        for next_index in range(index + 1, len(lines)):
            if re.match(r"^\\s*\\[", lines[next_index]):
                break
            if re.match(r"^\\s*#\\s*Include\\s*=\\s*/etc/pacman\\.d/mirrorlist\\s*$", lines[next_index]):
                lines[next_index] = "Include = /etc/pacman.d/mirrorlist"
                include_found = True
                break
            if re.match(r"^\\s*Include\\s*=\\s*/etc/pacman\\.d/mirrorlist\\s*$", lines[next_index]):
                include_found = True
                break
        if not include_found:
            lines.insert(index + 1, "Include = /etc/pacman.d/mirrorlist")
        break

if not found:
    lines.extend(["", "[multilib]", "Include = /etc/pacman.d/mirrorlist"])

path.write_text("\n".join(lines) + "\n")
PY
    then
        err "Could not enable multilib. The original config backup is at $backup."
        return 1
    fi

    ok "pacman.conf backed up to $backup"
    info "Refreshing package databases with a full system upgrade..."
    sudo pacman -Syu || {
        err "The full system upgrade did not complete. No branch packages were installed."
        return 1
    }

    pacman-conf --repo-list 2>/dev/null | grep -qx 'multilib' || {
        err "Multilib is still unavailable after updating pacman.conf."
        return 1
    }
    ok "Multilib is enabled."
}

# ri_package_install_targets <label> <required|optional> <packages...>
ri_package_install_targets() {
    local label="$1" mode="$2"
    shift 2

    local package spec conflict conflicts repo reason
    local metadata_file errors_file parsed_file installed_file installed_parsed_file
    local installed_package
    local failures=0 skips=0 transaction_status=0
    local -a requested=() pending=() repo_targets=() custom_targets=() aur_targets=()
    local conflict_text replacement_text
    local -a conflict_specs=() replacement_specs=()
    local -A seen=() package_repo=() package_conflicts=() package_replaces=() package_provides=()
    local -A installed_conflicts=() queued=()

    command -v pacman >/dev/null 2>&1 || {
        err "pacman is required for package installation."
        return 1
    }
    command -v paru >/dev/null 2>&1 || {
        err "paru is required for package installation."
        return 1
    }

    # Normalize package specs and remove duplicates.
    for package in "$@"; do
        package="${package%%#*}"
        package="$(printf '%s' "$package" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [[ -n $package ]] || continue
        package="$(ri_package_name_from_spec "$package")"
        [[ -n $package ]] || continue
        [[ ${seen[$package]+yes} ]] && continue
        seen[$package]=1
        requested+=("$package")
    done

    (("${#requested[@]}" > 0)) || {
        info "No packages selected for $label."
        return 0
    }

    # pacman -T understands Provides. This is important: if an installed
    # alternative already provides a requested package, it is satisfied and
    # must not be removed or replaced just to install the package's namesake.
    for package in "${requested[@]}"; do
        if pacman -T "$package" >/dev/null 2>&1; then
            info "Already satisfied: $package"
            continue
        fi
        pending+=("$package")
    done

    (("${#pending[@]}" > 0)) || {
        ok "All packages for $label are already installed or provided."
        return 0
    }

    metadata_file="$(mktemp "${TMPDIR:-/tmp}/riceinstaller-syncinfo.XXXXXX")"
    errors_file="$(mktemp "${TMPDIR:-/tmp}/riceinstaller-syncerr.XXXXXX")"
    parsed_file="$(mktemp "${TMPDIR:-/tmp}/riceinstaller-parsed.XXXXXX")"
    installed_file="$(mktemp "${TMPDIR:-/tmp}/riceinstaller-installed.XXXXXX")"
    installed_parsed_file="$(mktemp "${TMPDIR:-/tmp}/riceinstaller-installed-parsed.XXXXXX")"

    printf '\n\033[1;36m── %s (%s) ──\033[0m\n' "$label" "$mode"
    info "Checking package availability for this group..."

    # One metadata query for the whole target set, not one network transaction
    # per package. paru -Si reports both repository and AUR packages.
    LC_ALL=C paru -Si "${pending[@]}" >"$metadata_file" 2>"$errors_file" || true
    ri_package_parse_sync_info "$metadata_file" "$parsed_file"

    while IFS=$'\t' read -r package repo conflicts replaces _provides; do
        [[ -n $package ]] || continue
        package_repo[$package]="$repo"
        package_conflicts[$package]="$conflicts"
        package_replaces[$package]="$replaces"
        package_provides[$package]="$_provides"
    done <"$parsed_file"

    pacman -Qi >"$installed_file" 2>/dev/null || true
    ri_package_parse_installed_info "$installed_file" "$installed_parsed_file"
    while IFS=$'\t' read -r installed_package conflicts; do
        [[ -n $installed_package ]] || continue
        installed_conflicts[$installed_package]="$conflicts"
    done <"$installed_parsed_file"

    # Classify packages and filter unsafe conflicts before opening a package
    # transaction. Official Provides/Replaces metadata is the only automatic
    # removal authority; AUR/custom repositories never get that privilege.
    for package in "${pending[@]}"; do
        repo="${package_repo[$package]:-}"
        if [[ -z $repo ]]; then
            reason="not found in enabled repositories or the AUR"
            warn "$package is unavailable; skipping it."
            ri_package_record "$label" "$package" "$reason"
            if [[ $mode == required ]]; then failures=$((failures + 1)); else skips=$((skips + 1)); fi
            continue
        fi

        conflict_text="${package_conflicts[$package]:-}"
        replacement_text="${package_replaces[$package]:-}"
        conflict_specs=()
        replacement_specs=()
        read -r -a conflict_specs <<<"$conflict_text"
        read -r -a replacement_specs <<<"$replacement_text"
        local unsafe_conflict=""
        for spec in "${conflict_specs[@]}"; do
            [[ -n $spec && $spec != "None" ]] || continue
            conflict="$(ri_package_name_from_spec "$spec")"
            [[ -n $conflict ]] || continue
            if pacman -Qq "$conflict" >/dev/null 2>&1; then
                if ri_package_is_official_repo "$repo" && (
                    ri_package_list_has "$conflict" "${package_replaces[$package]:-}" ||
                    ri_package_list_has "$conflict" "${package_provides[$package]:-}"
                ); then
                    info "Official metadata permits $package to replace installed $conflict."
                else
                    unsafe_conflict="$conflict"
                    break
                fi
            fi
        done

        # Replaces can be declared without a matching Conflicts entry.
        # Only official Arch repositories may automatically replace an
        # installed package; AUR/custom package replacements are preserved.
        if [[ -z $unsafe_conflict ]]; then
            for spec in "${replacement_specs[@]}"; do
                [[ -n $spec && $spec != "None" ]] || continue
                conflict="$(ri_package_name_from_spec "$spec")"
                [[ -n $conflict ]] || continue
                if pacman -Qq "$conflict" >/dev/null 2>&1 &&
                    ! ri_package_is_official_repo "$repo"; then
                    unsafe_conflict="$conflict"
                    break
                fi
            done
        fi

        if [[ -z $unsafe_conflict ]]; then
            for installed_package in "${!installed_conflicts[@]}"; do
                if ri_package_list_has "$package" "${installed_conflicts[$installed_package]:-}"; then
                    if ri_package_is_official_repo "$repo" && (
                        ri_package_list_has "$installed_package" "${package_replaces[$package]:-}" ||
                        ri_package_list_has "$installed_package" "${package_provides[$package]:-}"
                    ); then
                        info "Official metadata permits $package to replace installed $installed_package."
                    else
                        unsafe_conflict="$installed_package"
                        break
                    fi
                fi
            done
        fi

        if [[ -n $unsafe_conflict ]]; then
            reason="conflicts with installed $unsafe_conflict; existing package preserved"
            warn "Keeping $unsafe_conflict and skipping $package."
            ri_package_record "$label" "$package" "$reason"
            if [[ $mode == required ]]; then failures=$((failures + 1)); else skips=$((skips + 1)); fi
            continue
        fi

        if [[ $repo == aur ]]; then
            aur_targets+=("$package")
        elif ri_package_is_official_repo "$repo"; then
            repo_targets+=("$package")
        else
            custom_targets+=("$package")
        fi
    done

    rm -f "$metadata_file" "$errors_file" "$parsed_file" "$installed_file" "$installed_parsed_file"

    # Detect mutually exclusive targets inside the requested set. Do not
    # arbitrarily choose one: that would make the resulting rice incomplete.
    for package in "${repo_targets[@]}" "${custom_targets[@]}" "${aur_targets[@]}"; do
        queued[$package]=1
    done
    local -a all_targets=("${repo_targets[@]}" "${custom_targets[@]}" "${aur_targets[@]}")
    local -a filtered_repo=() filtered_custom=() filtered_aur=()
    for package in "${all_targets[@]}"; do
        [[ ${queued[$package]:-0} == 1 ]] || continue
        conflict_specs=()
        read -r -a conflict_specs <<<"${package_conflicts[$package]:-}"
        for spec in "${conflict_specs[@]}"; do
            [[ -n $spec && $spec != "None" ]] || continue
            conflict="$(ri_package_name_from_spec "$spec")"
            [[ -n $conflict && $conflict != "$package" ]] || continue
            if [[ ${queued[$conflict]:-0} == 1 ]]; then
                if ri_package_is_official_repo "${package_repo[$package]:-}" && (
                    ri_package_list_has "$conflict" "${package_replaces[$package]:-}" ||
                    ri_package_list_has "$conflict" "${package_provides[$package]:-}"
                ); then
                    queued[$conflict]=0
                    ri_package_record "$label" "$conflict" "superseded by official package $package in the same package plan"
                    skips=$((skips + 1))
                else
                    queued[$package]=0
                    queued[$conflict]=0
                    ri_package_record "$label" "$package" "mutually conflicts with requested package $conflict; neither was installed"
                    ri_package_record "$label" "$conflict" "mutually conflicts with requested package $package; neither was installed"
                    failures=$((failures + 1))
                fi
            fi
        done
    done

    for package in "${repo_targets[@]}"; do
        [[ ${queued[$package]:-0} == 1 ]] && filtered_repo+=("$package")
    done
    for package in "${custom_targets[@]}"; do
        [[ ${queued[$package]:-0} == 1 ]] && filtered_custom+=("$package")
    done
    for package in "${aur_targets[@]}"; do
        [[ ${queued[$package]:-0} == 1 ]] && filtered_aur+=("$package")
    done
    repo_targets=("${filtered_repo[@]}")
    custom_targets=("${filtered_custom[@]}")
    aur_targets=("${filtered_aur[@]}")

    printf '\n'
    info "$label package plan: ${#repo_targets[@]} official, ${#custom_targets[@]} custom-repository, ${#aur_targets[@]} AUR package(s), $skips safely skipped."
    info "The package manager will display live download and installation progress. Review its confirmation prompt before proceeding."
    if (("${#repo_targets[@]}" > 0)); then
        printf '\n\033[1;34mOfficial Arch repository packages (%d)\033[0m\n' "${#repo_targets[@]}"
        printf '  • %s\n' "${repo_targets[@]}"
        info "Downloading and installing official packages..."
        if command -v pactrans >/dev/null 2>&1; then
            transaction_status=0
            if [[ -t 0 ]]; then
                sudo pactrans --install --resolve-conflicts=provided --resolve-replacements=all "${repo_targets[@]}" ||
                    transaction_status=$?
            else
                # pactrans reads package specs from stdin when stdin is not a
                # terminal; close it because all targets were passed as args.
                sudo pactrans --install --resolve-conflicts=provided --resolve-replacements=all "${repo_targets[@]}" <&- ||
                    transaction_status=$?
            fi
        else
            sudo pacman -S --needed "${repo_targets[@]}" || transaction_status=$?
        fi
        if ((transaction_status != 0)); then
            err "Repository package transaction failed."
            for package in "${repo_targets[@]}"; do
                ri_package_record "$label" "$package" "repository transaction failed"
            done
            failures=$((failures + 1))
        else
            ok "Official repository package transaction completed."
        fi
    fi

    if (("${#custom_targets[@]}" > 0)); then
        printf '\n\033[1;34mCustom repository packages (%d)\033[0m\n' "${#custom_targets[@]}"
        printf '  • %s\n' "${custom_targets[@]}"
        info "Downloading and installing custom-repository packages (normal package-manager safety prompts retained)..."
        if ! sudo pacman -S --needed "${custom_targets[@]}"; then
            err "Custom-repository package transaction failed."
            for package in "${custom_targets[@]}"; do
                ri_package_record "$label" "$package" "custom-repository transaction failed"
            done
            failures=$((failures + 1))
        else
            ok "Custom repository package transaction completed."
        fi
    fi

    if (("${#aur_targets[@]}" > 0)); then
        printf '\n\033[1;34mAUR packages (%d)\033[0m\n' "${#aur_targets[@]}"
        printf '  • %s\n' "${aur_targets[@]}"
        info "Building, downloading and installing AUR packages..."
        if ! paru -S --needed "${aur_targets[@]}"; then
            err "AUR package transaction failed."
            for package in "${aur_targets[@]}"; do
                ri_package_record "$label" "$package" "AUR transaction failed"
            done
            failures=$((failures + 1))
        else
            ok "AUR package transaction completed."
        fi
    fi

    if ((failures > 0)); then
        err "$label could not be completed. See $RI_PACKAGE_REPORT."
        return 1
    fi
    ok "$label package plan completed."
    return 0
}

ri_package_install_file() {
    local file="$1" label="$2" mode="$3" package
    local -a packages=()

    [[ -f $file ]] || {
        err "Package list not found: $file"
        return 1
    }

    while IFS= read -r package || [[ -n $package ]]; do
        package="${package%%#*}"
        package="$(printf '%s' "$package" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [[ -n $package ]] && packages+=("$package")
    done <"$file"

    ri_package_install_targets "$label" "$mode" "${packages[@]}"
}

ri_package_install_string() {
    local label="$1" mode="$2" package_string="$3"
    local -a packages=()
    read -r -a packages <<<"$package_string"
    ri_package_install_targets "$label" "$mode" "${packages[@]}"
}
