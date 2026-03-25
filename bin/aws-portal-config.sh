#!/usr/bin/env bash
# aws-portal-config — Sync ~/.aws/config via the AWS SSO portal API
#
# Logs in with a named profile, extracts the bearer token from the local SSO
# cache, fetches every account the caller can see through the portal REST API,
# then rewrites the matching profile blocks in ~/.aws/config after showing a
# unified diff for review.

set -euo pipefail

readonly PROGRAM="${0##*/}"
readonly CONFIG="${HOME}/.aws/config"
readonly SSO_REGION='us-east-1'   # portal API is always in us-east-1

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

usage() {
    cat >&2 <<EOF
Usage: $PROGRAM -s SESSION [OPTIONS]

Log in to AWS SSO, fetch the account list from the portal API, and update
~/.aws/config.  Existing profiles belonging to SESSION are replaced; every
other section is preserved.

Options:
  -s SESSION  SSO session name (required; must match an [sso-session] block
              in ~/.aws/config so the start URL can be looked up)
  -l PROFILE  Profile used for "aws sso login" (default: default-profile)
  -r ROLE     sso_role_name written into each profile (default: AdministratorAccess)
  -p PREFIX   Profile name prefix, e.g. AdminAccess  (default: same as ROLE)
  -g REGION   Default region written into each profile (default: us-east-2)
              (The SSO portal API always uses us-east-1 regardless of this value)
  -h          Show this help

Example:
  $PROGRAM -s sso-session -l default-profile -p AdminAccess -g us-east-2
EOF
    exit "${1:-0}"
}

die() {
    printf '%s: %s\n' "$PROGRAM" "$*" >&2
    exit 1
}

# Prompt on /dev/tty so confirmation works even when stdin is redirected.
confirm() {
    local reply
    printf '%s [y/N] ' "$*" >/dev/tty
    read -r reply </dev/tty
    [[ $reply == [yY] || $reply == [yY][eE][sS] ]]
}

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------

check_deps() {
    local dep missing=0
    for dep in aws curl jq; do
        if ! command -v "$dep" &>/dev/null; then
            printf '%s: required tool not found: %s\n' "$PROGRAM" "$dep" >&2
            missing=1
        fi
    done
    (( ! missing )) || exit 1
}

# ---------------------------------------------------------------------------
# SSO helpers
# ---------------------------------------------------------------------------

# Read sso_start_url from the [sso-session SESSION] block in CONFIG.
get_start_url() {
    local session=$1

    awk -v session="$session" '
        /^\[/ {
            in_session = ($0 == "[sso-session " session "]")
            next
        }
        in_session && /^[[:space:]]*sso_start_url[[:space:]]*=/ {
            sub(/^[[:space:]]*sso_start_url[[:space:]]*=[[:space:]]*/, "")
            sub(/[[:space:]]*$/, "")
            print
            exit
        }
    ' "$CONFIG"
}

# Extract a non-expired access token for START_URL from the local SSO cache.
# expiresAt is an ISO-8601 string (e.g. "2026-03-25T18:00:00UTC"); lexicographic
# comparison against the current UTC time is correct for this format.
get_token() {
    local start_url=$1
    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SUTC)

    jq -r --arg start "$start_url" --arg now "$now" '
        select(.startUrl == $start)
        | select((.expiresAt // "") > $now)
        | .accessToken
    ' ~/.aws/sso/cache/*.json | tail -n1
}

# Fetch every account visible through the portal API; emit "name<TAB>id" lines.
fetch_accounts() {
    local token=$1
    local base_url="https://portal.sso.${SSO_REGION}.amazonaws.com/assignment/accounts"
    local response

    response=$(curl -sf \
        -H "x-amz-sso_bearer_token: ${token}" \
        "$base_url")
    jq -r '.accountList | sort_by(.accountName) | .[] | [.accountName, .accountId] | @tsv' \
        <<< "$response"
}

# ---------------------------------------------------------------------------
# Config generation
# ---------------------------------------------------------------------------

# Read "name<TAB>id" lines from stdin; write AWS config profile stanzas.
generate_profiles() {
    local session=$1 role=$2 prefix=$3 region=$4
    local name id

    while IFS=$'\t' read -r name id; do
        printf '\n[profile %s-%s]\n' "$prefix" "$name"
        printf 'sso_session = %s\n'    "$session"
        printf 'sso_account_id = %s\n' "$id"
        printf 'sso_role_name = %s\n'  "$role"
        printf 'region = %s\n'         "$region"
        printf 'cli_pager =\n'
    done
}

# Write FILE to stdout, omitting any profile section whose sso_session value
# equals SESSION.  Every other section (default, sso-session, other profiles)
# is passed through unchanged.
filter_config() {
    local file=$1 session=$2

    awk -v session="$session" '
        # A line starting with [ marks the beginning of a new section.
        # Flush whatever we accumulated for the previous section first.
        /^\[/ {
            if (buf != "" && !skip)
                printf "%s", buf
            buf  = $0 "\n"
            skip = 0
            next
        }

        # Accumulate lines into the buffer for the current section.
        {
            buf = buf $0 "\n"

            # Detect "sso_session = <value>" tolerating spaces around "=".
            if ($0 ~ /^[[:space:]]*sso_session[[:space:]]*=/) {
                val = $0
                sub(/^[[:space:]]*sso_session[[:space:]]*=[[:space:]]*/, "", val)
                sub(/[[:space:]]*$/, "", val)
                if (val == session)
                    skip = 1
            }
        }

        END {
            if (buf != "" && !skip)
                printf "%s", buf
        }
    ' "$file"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    local sso_session='' sso_role='AdministratorAccess' prefix='' region='us-east-2'
    local login_profile='default-profile'
    local opt

    while getopts ':s:l:r:p:g:h' opt; do
        case $opt in
            s) sso_session=$OPTARG    ;;
            l) login_profile=$OPTARG  ;;
            r) sso_role=$OPTARG       ;;
            p) prefix=$OPTARG         ;;
            g) region=$OPTARG         ;;
            h) usage 0                ;;
            :) die "option -$OPTARG requires an argument" ;;
            ?) die "unknown option: -$OPTARG"             ;;
        esac
    done
    shift $((OPTIND - 1))

    [[ -n $sso_session ]] || die "SSO session name is required (-s SESSION)"
    [[ -n $prefix ]]      || prefix=$sso_role

    check_deps

    # -----------------------------------------------------------------------
    # Resolve the portal start URL from the existing config.
    # -----------------------------------------------------------------------
    [[ -f $CONFIG ]] || die "config not found: $CONFIG — create an [sso-session] block first"

    local start_url
    start_url=$(get_start_url "$sso_session")
    [[ -n $start_url ]] || \
        die "sso_start_url not found for session \"$sso_session\" in $CONFIG"

    printf '%s: start URL: %s\n' "$PROGRAM" "$start_url" >&2

    # -----------------------------------------------------------------------
    # Reuse a cached token when possible; log in only when necessary.
    # -----------------------------------------------------------------------
    local token
    token=$(get_token "$start_url") || true

    if [[ -z $token ]]; then
        printf '%s: no valid token in cache; running: aws sso login --profile "%s"\n' \
            "$PROGRAM" "$login_profile" >&2
        aws sso login --profile "$login_profile"
        token=$(get_token "$start_url")
        [[ -n $token ]] || die "no valid SSO access token found in cache after login"
    else
        printf '%s: reusing existing valid SSO token\n' "$PROGRAM" >&2
    fi

    # -----------------------------------------------------------------------
    # Fetch the account list from the portal API.
    # -----------------------------------------------------------------------
    printf '%s: fetching account list from portal (sso region: %s)...\n' "$PROGRAM" "$SSO_REGION" >&2

    local accounts
    accounts=$(fetch_accounts "$token") || true
    [[ -n $accounts ]] || die "no accounts returned from portal"

    local count
    count=$(awk 'END { print NR }' <<< "$accounts")
    printf '%s: found %d account(s) for session "%s"\n' \
        "$PROGRAM" "$count" "$sso_session" >&2

    # -----------------------------------------------------------------------
    # Temp file — global so the EXIT trap can reference it after main() returns.
    # -----------------------------------------------------------------------
    tmp_config=$(mktemp) || die "cannot create temp file"
    trap 'rm -f "$tmp_config"' EXIT

    # -----------------------------------------------------------------------
    # Assemble the new config:
    #   1. All existing sections except profiles for this SSO session.
    #   2. Freshly generated profile blocks for every fetched account.
    # -----------------------------------------------------------------------
    if [[ -s $CONFIG ]]; then
        # Strip trailing blank lines so the leading '\n' in each generated
        # profile block always produces exactly one blank line separator.
        filter_config "$CONFIG" "$sso_session" \
            | awk '/^[[:space:]]*$/{pending=pending $0 "\n"; next}
                   {printf "%s%s\n", pending, $0; pending=""}' \
            > "$tmp_config"
    fi

    printf '%s\n' "$accounts" \
        | generate_profiles "$sso_session" "$sso_role" "$prefix" "$region" \
        >> "$tmp_config"

    # -----------------------------------------------------------------------
    # Show a diff so the user can review every change before committing.
    # -----------------------------------------------------------------------
    printf '\n' >&2

    local has_diff=0
    diff -u "$CONFIG" "$tmp_config" || has_diff=1

    if (( ! has_diff )); then
        printf '\n%s: config is already up to date — no changes needed\n' \
            "$PROGRAM" >&2
        exit 0
    fi

    printf '\n' >&2
    if confirm "Install updated config to $CONFIG?"; then
        cp -- "$tmp_config" "$CONFIG"
        printf '%s: config updated (%d profile(s) for session "%s")\n' \
            "$PROGRAM" "$count" "$sso_session" >&2
    else
        printf '%s: aborted — no changes made\n' "$PROGRAM" >&2
        exit 1
    fi
}

main "$@"
