#!/usr/bin/env bash
set -Eeuo pipefail

readonly INSTALL_DIR="/usr/local/s-ui"
readonly SERVICE_FILE="/etc/systemd/system/s-ui.service"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_DIR="${SCRIPT_DIR}/s-ui"

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

[[ ${EUID} -eq 0 ]] || die "run this installer as root"
[[ "$(uname -s)" == "Linux" ]] || die "this package only supports Linux"

case "$(uname -m)" in
    x86_64 | amd64) ;;
    *) die "this package requires an amd64/x86_64 server" ;;
esac

command -v systemctl >/dev/null 2>&1 || die "systemd is required"
[[ -x "${SOURCE_DIR}/sui" ]] || die "missing ${SOURCE_DIR}/sui"
[[ -f "${SOURCE_DIR}/s-ui.service" ]] || die "missing ${SOURCE_DIR}/s-ui.service"

if [[ -n "${SUI_ADMIN_USER:-}" || -n "${SUI_ADMIN_PASS:-}" ]]; then
    [[ -n "${SUI_ADMIN_USER:-}" && -n "${SUI_ADMIN_PASS:-}" ]] || \
        die "set both SUI_ADMIN_USER and SUI_ADMIN_PASS, or neither"
fi

is_new_install=1
if [[ -f "${INSTALL_DIR}/db/s-ui.db" ]]; then
    is_new_install=0
    backup_dir="/var/backups/s-ui/$(date -u +%Y%m%dT%H%M%SZ)"
    install -d -m 0700 "${backup_dir}"
    cp -a "${INSTALL_DIR}/db/s-ui.db" "${backup_dir}/s-ui.db"
    printf 'Existing database backed up to %s\n' "${backup_dir}/s-ui.db"
fi

if systemctl list-unit-files s-ui.service >/dev/null 2>&1; then
    systemctl stop s-ui.service || true
fi

install -d -m 0700 "${INSTALL_DIR}"
install -m 0755 "${SOURCE_DIR}/sui" "${INSTALL_DIR}/sui"
install -m 0644 "${SOURCE_DIR}/s-ui.service" "${SERVICE_FILE}"

"${INSTALL_DIR}/sui" migrate

generated_credentials=0
if [[ ${is_new_install} -eq 1 ]]; then
    admin_user="${SUI_ADMIN_USER:-}"
    admin_pass="${SUI_ADMIN_PASS:-}"
    if [[ -z "${admin_user}" ]]; then
        random_user_suffix="$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')"
        random_password="$(od -An -N20 -tx1 /dev/urandom | tr -d ' \n')"
        admin_user="admin_${random_user_suffix}"
        admin_pass="${random_password}"
        generated_credentials=1
    fi
    "${INSTALL_DIR}/sui" admin -username "${admin_user}" -password "${admin_pass}"
fi

systemctl daemon-reload
systemctl enable --now s-ui.service

printf '\ns-ui v1.5.5 hardened build is running.\n'
if [[ ${generated_credentials} -eq 1 ]]; then
    printf 'Generated username: %s\n' "${admin_user}"
    printf 'Generated password: %s\n' "${admin_pass}"
    printf 'Store these credentials now; the password is hashed in the database.\n'
elif [[ ${is_new_install} -eq 1 ]]; then
    printf 'The supplied administrator credentials were installed.\n'
else
    printf 'Existing credentials and database settings were preserved.\n'
fi

printf '\nThe hardened defaults listen only on localhost. From your computer, use:\n'
printf '  ssh -L 2095:127.0.0.1:2095 root@YOUR_SERVER\n'
printf 'Then open:\n'
printf '  http://127.0.0.1:2095/app/\n'
printf '\nService status:\n'
systemctl --no-pager --full status s-ui.service || true
