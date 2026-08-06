#!/usr/bin/env bash
# Read-only verifier for TC-01 User and Access Management.
# Usage: verify-user-access.sh <username> [expected-privileged-group]

set -u
set -o pipefail

usage() {
  printf 'Usage: %s <username> [expected-privileged-group]\n' "$0" >&2
}

emit() {
  printf '%s=%s\n' "$1" "$2"
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 64
fi

username=$1
expected_group=${2:-}

case "$username" in
  ''|[-]*|*[!a-z0-9_-]*)
    emit "input_status" "FAIL"
    emit "input_message" "username format rejected by conservative local-account validator"
    exit 64
    ;;
esac

case "$username" in
  [a-z_]* ) ;;
  * )
    emit "input_status" "FAIL"
    emit "input_message" "username must start with a lowercase letter or underscore"
    exit 64
    ;;
esac

emit "control" "TC-01"
emit "mode" "read-only-verification"
emit "target_user" "$username"
emit "hostname" "$(hostname 2>/dev/null || printf 'UNKNOWN')"
emit "checked_by" "$(id -un 2>/dev/null || printf 'UNKNOWN')"
emit "checked_at" "$(date --iso-8601=seconds 2>/dev/null || date 2>/dev/null || printf 'UNKNOWN')"

os_id=unknown
os_like=unknown
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  os_id=${ID:-unknown}
  os_like=${ID_LIKE:-unknown}
fi
emit "os_id" "$os_id"
emit "os_like" "$os_like"

if [ -z "$expected_group" ]; then
  case " $os_id $os_like " in
    *debian*|*ubuntu*) expected_group=sudo ;;
    *rhel*|*fedora*|*centos*) expected_group=wheel ;;
    *) expected_group=UNKNOWN ;;
  esac
fi
emit "expected_privileged_group" "$expected_group"

passwd_entry=$(getent passwd "$username" 2>/dev/null || true)
if [ -z "$passwd_entry" ]; then
  emit "account_exists" "FAIL"
  emit "final_status" "FAIL"
  emit "message" "account not found through getent"
  exit 2
fi
emit "account_exists" "PASS"

IFS=: read -r account_name _ account_uid account_gid account_gecos account_home account_shell <<EOF
$passwd_entry
EOF

emit "account_name" "$account_name"
emit "uid" "$account_uid"
emit "primary_gid" "$account_gid"
emit "gecos" "$account_gecos"
emit "home" "$account_home"
emit "shell" "$account_shell"

id_output=$(id "$username" 2>/dev/null || true)
if [ -n "$id_output" ]; then
  emit "id_lookup" "PASS"
  emit "id_summary" "$id_output"
else
  emit "id_lookup" "FAIL"
fi

group_names=$(id -nG "$username" 2>/dev/null || true)
emit "supplementary_groups" "${group_names:-UNKNOWN}"

group_status=NOT_TESTED
if [ "$expected_group" != "UNKNOWN" ]; then
  if getent group "$expected_group" >/dev/null 2>&1; then
    emit "privileged_group_exists" "PASS"
    if printf '%s\n' "$group_names" | tr ' ' '\n' | grep -Fxq -- "$expected_group"; then
      group_status=PASS
    else
      group_status=FAIL
    fi
  else
    emit "privileged_group_exists" "FAIL"
    group_status=FAIL
  fi
else
  emit "privileged_group_exists" "NOT_TESTED"
fi
emit "privileged_group_membership" "$group_status"

home_status=FAIL
home_owner=UNKNOWN
if [ -d "$account_home" ]; then
  home_owner=$(stat -c '%U:%G' -- "$account_home" 2>/dev/null || printf 'UNKNOWN')
  home_uid=$(stat -c '%u' -- "$account_home" 2>/dev/null || printf 'UNKNOWN')
  if [ "$home_uid" = "$account_uid" ]; then
    home_status=PASS
  fi
fi
emit "home_directory" "$home_status"
emit "home_owner" "$home_owner"

if [ -x "$account_shell" ]; then
  emit "login_shell_exists" "PASS"
else
  emit "login_shell_exists" "FAIL"
fi

password_status=NOT_TESTED
password_detail=UNAVAILABLE
if command -v passwd >/dev/null 2>&1; then
  password_line=$(passwd -S "$username" 2>/dev/null || true)
  if [ -n "$password_line" ]; then
    password_detail=$password_line
    password_code=$(printf '%s\n' "$password_line" | tr -s ' ' | cut -d' ' -f2)
    case "$password_code" in
      P|PS) password_status=PASS ;;
      L|LK|NP) password_status=FAIL ;;
      *) password_status=NOT_TESTED ;;
    esac
  fi
fi
emit "password_status" "$password_status"
emit "password_status_detail" "$password_detail"

aging_status=NOT_TESTED
aging_summary=UNAVAILABLE
if command -v chage >/dev/null 2>&1; then
  aging_output=$(chage -l "$username" 2>/dev/null || true)
  if [ -n "$aging_output" ]; then
    aging_status=PASS
    aging_summary=$(printf '%s\n' "$aging_output" | tr '\n' ';' | sed 's/;*$//')
  fi
fi
emit "password_aging_readable" "$aging_status"
emit "password_aging_summary" "$aging_summary"

sudo_status=NOT_TESTED
if command -v sudo >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    if sudo -n -l -U "$username" >/dev/null 2>&1; then
      sudo_status=PASS
    else
      sudo_status=FAIL
    fi
  elif sudo -n -l -U "$username" >/dev/null 2>&1; then
    sudo_status=PASS
  fi
fi
emit "effective_sudo_policy" "$sudo_status"

final_status=PASS
for status in "$group_status" "$home_status" "$password_status" "$sudo_status"; do
  if [ "$status" = "FAIL" ]; then
    final_status=FAIL
    break
  fi
  if [ "$status" = "NOT_TESTED" ] && [ "$final_status" = "PASS" ]; then
    final_status=NOT_TESTED
  fi
done

emit "final_status" "$final_status"

case "$final_status" in
  PASS) exit 0 ;;
  NOT_TESTED) exit 3 ;;
  *) exit 1 ;;
esac
