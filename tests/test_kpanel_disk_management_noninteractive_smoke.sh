#!/bin/bash
set -euo pipefail

project_root="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
script_path="${project_root}/kejilion.sh"
cn_script_path="${project_root}/cn/kejilion.sh"
test_root="$(mktemp -d)"
mock_bin="${test_root}/bin"
test_stderr="${test_root}/stderr"
test_stdout="${test_root}/stdout"
mock_log="${test_root}/commands.log"
mock_mounts="${test_root}/mounts"
mock_fstype="${test_root}/fstype"
mock_fstab="${test_root}/fstab"
mock_swaps="${test_root}/swaps"
mock_holders="${test_root}/holders"
mock_state="${test_root}/state"
mock_lock_parent="${test_root}/run-lock"
mock_lock="${mock_lock_parent}/kejilion-kpanel-disk.lock"
mock_verify_log="${test_root}/verify.log"
mock_verify_fail_postwrite="${test_root}/verify-fail-postwrite"
trap 'rm -rf -- "${test_root}"' EXIT

fail() {
	printf 'FAIL: %s\n' "$1" >&2
	if [ -s "${test_stderr}" ]; then
		printf '%s\n' '--- adapter stderr ---' >&2
		command cat -- "${test_stderr}" >&2
	fi
	exit 1
}

assert_file_line() {
	local expected="$1" file="$2"
	expected="${expected//\\t/$'\t'}"
	grep -Fqx -- "${expected}" "${file}" || fail "missing exact command: ${expected}"
}

grep -F '[ "${KJ_DISK_MANAGEMENT_NONINTERACTIVE:-}" = "1" ] ||' "${script_path}" >/dev/null
grep -F 'KPANEL_DISK_MANAGEMENT_PROTOCOL_VERSION="1"' "${script_path}" >/dev/null
grep -F 'kpanel_disk_management_dispatch "$@"' "${script_path}" >/dev/null
grep -F 'printf '\''%s\n'\'' "/run/lock/kejilion-kpanel-disk.lock"' "${script_path}" >/dev/null
grep -F 'flock -w 5 -x 9' "${script_path}" >/dev/null
grep -F 'kpanel_system_resource_path_has_no_symlink "$mountpoint"' "${script_path}" >/dev/null
grep -F '[ "${#encoded}" -le 8192 ]' "${script_path}" >/dev/null
grep -F 'kpanel_disk_management_prune_fstab_backups 15' "${script_path}" >/dev/null
grep -F 'mount --source "$KPANEL_DISK_MANAGEMENT_DEVICE_PATH" --target "$KPANEL_DISK_MANAGEMENT_MOUNTPOINT"' "${script_path}" >/dev/null
grep -F 'umount -- "$KPANEL_DISK_MANAGEMENT_MOUNTPOINT"' "${script_path}" >/dev/null
if grep -E 'umount[[:space:]]+(-f|-l|--force|--lazy)' "${script_path}" >/dev/null; then
	fail "disk-management must not force or lazy unmount"
fi

system_body="$(
	sed -n '/^# KPanel system resource protocol start/,/^# KPanel system resource protocol end/p' "${script_path}" |
		sed 's/\r$//'
)"
disk_body="$(
	sed -n '/^# KPanel disk management protocol start/,/^# KPanel disk management protocol end/p' "${script_path}" |
		sed 's/\r$//'
)"
cn_disk_body="$(
	sed -n '/^# KPanel disk management protocol start/,/^# KPanel disk management protocol end/p' "${cn_script_path}" |
		sed 's/\r$//'
)"
[ -n "${system_body}" ] || fail "system-resource dependency block was not found"
[ -n "${disk_body}" ] || fail "disk-management adapter block was not found"
[ "$(grep -Fxc 'KPANEL_DISK_MANAGEMENT_PROTOCOL_VERSION="1"' <<< "${disk_body}")" -eq 1 ] ||
	fail "disk-management protocol marker must be unique"
[ "${disk_body}" = "${cn_disk_body}" ] || fail "root and cn disk-management blocks differ"
if grep -F 'rm -rf' <<< "${disk_body}" >/dev/null; then
	fail "disk-management backup cleanup must not use broad recursive removal"
fi

normalized_script="${test_root}/kejilion.normalized.sh"
sed 's/\r$//' "${script_path}" > "${normalized_script}"
set +e
KJ_DISK_MANAGEMENT_NONINTERACTIVE=1 bash "${normalized_script}" kpanel disk-management unknown \
	>"${test_stdout}" 2>"${test_stderr}"
entry_rc=$?
set -e
[ "${entry_rc}" -ne 0 ] || fail "unknown entry action unexpectedly succeeded"
mapfile -t entry_lines < "${test_stdout}"
[ "${#entry_lines[@]}" -eq 5 ] || fail "entry must emit exactly five receipt lines"
[ "${entry_lines[0]}" = 'KPANEL_DISK_MANAGEMENT_PROTOCOL 1' ] || fail "entry protocol header mismatch"
[ "${entry_lines[1]}" = 'KPANEL_DISK_MANAGEMENT_STATUS=failed' ] || fail "entry failure status mismatch"
[[ "${entry_lines[2]}" =~ ^KPANEL_DISK_MANAGEMENT_DEVICE=([0-9]+:[0-9]+)?$ ]] || fail "entry device field mismatch"
[[ "${entry_lines[3]}" =~ ^KPANEL_DISK_MANAGEMENT_MESSAGE_HEX=[0-9a-f]+$ ]] || fail "entry message field mismatch"
[ "${entry_lines[4]}" = 'KPANEL_DISK_MANAGEMENT_BACKUP_HEX=' ] || fail "entry backup field mismatch"

eval "${system_body}"
eval "${disk_body}"

mkdir -p -- "${mock_bin}" "${mock_holders}" "${mock_lock_parent}"
chmod 700 "${mock_lock_parent}"
printf 'Filename\tType\tSize\tUsed\tPriority\n' > "${mock_swaps}"

cat > "${mock_bin}/lsblk" <<'MOCK_LSBLK'
#!/bin/bash
set -u
if [ "${MOCK_LSBLK_MODE:-}" = fail ]; then
	exit 71
fi
if [ "$#" -eq 5 ] && [ "$1" = --noheadings ] && [ "$2" = --raw ] && [ "$3" = --paths ] &&
	[ "$4" = --output ] && [ "$5" = MAJ:MIN,PATH ]; then
	case "${MOCK_LSBLK_MODE:-normal}" in
		normal) printf '8:1 /dev/kpanel-test-disk\n' ;;
		duplicate) printf '8:1 /dev/kpanel-test-disk\n8:1 /dev/kpanel-test-disk-alias\n' ;;
		malformed) printf 'unexpected output\n' ;;
		*) exit 72 ;;
	esac
	exit 0
fi
if [ "$#" -eq 7 ] && [ "$1" = --nodeps ] && [ "$2" = --noheadings ] && [ "$3" = --raw ] &&
	[ "$4" = --output ] && [ "$6" = -- ] && [ "$7" = /dev/kpanel-test-disk ]; then
	case "$5" in
		MAJ:MIN) printf '8:1\n' ;;
		TYPE) printf 'part\n' ;;
		RO) printf '%s\n' "${MOCK_DEVICE_RO:-0}" ;;
		FSTYPE) command cat -- "${MOCK_FSTYPE}" ;;
		*) exit 73 ;;
	esac
	exit 0
fi
if [ "$#" -eq 6 ] && [ "$1" = --noheadings ] && [ "$2" = --raw ] &&
	[ "$3" = --output ] && [ "$4" = MAJ:MIN ] && [ "$5" = -- ] && [ "$6" = /dev/kpanel-test-disk ]; then
	printf '8:1\n'
	[ "${MOCK_LSBLK_CHILD:-0}" != 1 ] || printf '8:2\n'
	exit 0
fi
printf 'unexpected lsblk argv: %s\n' "$*" >&2
exit 74
MOCK_LSBLK

cat > "${mock_bin}/findmnt" <<'MOCK_FINDMNT'
#!/bin/bash
set -u
if [ "$#" -eq 5 ] && [ "$1" = --kernel ] && [ "$2" = --raw ] && [ "$3" = --noheadings ] &&
	[ "$4" = --output ] && [ "$5" = MAJ:MIN ]; then
	[ "${MOCK_FINDMNT_READ_FAIL:-0}" != 1 ] || exit 75
	awk -F '\t' 'NF >= 2 {print $1}' "${MOCK_MOUNTS}"
	exit 0
fi
if [ "$#" -eq 7 ] && [ "$1" = --kernel ] && [ "$2" = --raw ] && [ "$3" = --noheadings ] &&
	[ "$4" = --output ] && [ "$5" = MAJ:MIN ] && [ "$6" = --mountpoint ]; then
	[ "${MOCK_FINDMNT_READ_FAIL:-0}" != 1 ] || exit 75
	value="$(awk -F '\t' -v target="$7" '$2 == target {print $1}' "${MOCK_MOUNTS}")"
	[ -n "${value}" ] || exit 1
	printf '%s\n' "${value}"
	exit 0
fi
if [ "$#" -eq 3 ] && [ "$1" = --verify ] && [ "$2" = --tab-file ]; then
	printf 'verify\t%s\n' "$3" >> "${MOCK_VERIFY_LOG}"
	count="$(wc -l < "${MOCK_VERIFY_LOG}" | tr -d '[:space:]')"
	if [ -e "${MOCK_VERIFY_FAIL_POSTWRITE}" ] && [ "${count}" -eq 3 ]; then
		printf 'mock fstab verification failure\n' >&2
		exit 76
	fi
	[ -f "$3" ] || exit 77
	exit 0
fi
printf 'unexpected findmnt argv: %s\n' "$*" >&2
exit 78
MOCK_FINDMNT

cat > "${mock_bin}/blkid" <<'MOCK_BLKID'
#!/bin/bash
set -u
case "$*" in
	'-p -c /dev/null -s TYPE -o value /dev/kpanel-test-disk')
		command cat -- "${MOCK_FSTYPE}"
		;;
	'-c /dev/null -s UUID -o value /dev/kpanel-test-disk')
		case "${MOCK_BLKID_MODE:-normal}" in
			normal) printf 'kpanel-test-uuid\n' ;;
			no-uuid|no-id) exit 2 ;;
			*) exit 79 ;;
		esac
		;;
	'-c /dev/null -s PARTUUID -o value /dev/kpanel-test-disk')
		case "${MOCK_BLKID_MODE:-normal}" in
			no-uuid) printf 'kpanel-test-partuuid\n' ;;
			no-id) exit 2 ;;
			normal) printf 'kpanel-test-partuuid\n' ;;
			*) exit 79 ;;
		esac
		;;
	*) printf 'unexpected blkid argv: %s\n' "$*" >&2; exit 80 ;;
esac
MOCK_BLKID

cat > "${mock_bin}/mount" <<'MOCK_MOUNT'
#!/bin/bash
set -u
printf 'mount' >> "${MOCK_LOG}"
printf '\t%s' "$@" >> "${MOCK_LOG}"
printf '\n' >> "${MOCK_LOG}"
[ "$#" -eq 4 ] && [ "$1" = --source ] && [ "$2" = /dev/kpanel-test-disk ] && [ "$3" = --target ] || exit 81
[ "${MOCK_FAIL_COMMAND:-}" != mount ] || exit 82
printf '8:1\t%s\n' "$4" >> "${MOCK_MOUNTS}"
MOCK_MOUNT

cat > "${mock_bin}/umount" <<'MOCK_UMOUNT'
#!/bin/bash
set -u
printf 'umount' >> "${MOCK_LOG}"
printf '\t%s' "$@" >> "${MOCK_LOG}"
printf '\n' >> "${MOCK_LOG}"
[ "$#" -eq 2 ] && [ "$1" = -- ] || exit 83
[ "${MOCK_FAIL_COMMAND:-}" != umount ] || exit 84
temporary="${MOCK_MOUNTS}.tmp"
awk -F '\t' -v target="$2" '$2 != target {print}' "${MOCK_MOUNTS}" > "${temporary}" || exit 85
mv -f -- "${temporary}" "${MOCK_MOUNTS}"
MOCK_UMOUNT

cat > "${mock_bin}/mock-mkfs" <<'MOCK_MKFS'
#!/bin/bash
set -u
name="${0##*/}"
printf '%s' "${name}" >> "${MOCK_LOG}"
printf '\t%s' "$@" >> "${MOCK_LOG}"
printf '\n' >> "${MOCK_LOG}"
[ "${MOCK_FAIL_COMMAND:-}" != "${name}" ] || exit 86
case "${name}" in
	mkfs.ext4) [ "$#" -eq 2 ] && [ "$1" = -F ] && [ "$2" = /dev/kpanel-test-disk ] && fstype=ext4 ;;
	mkfs.xfs) [ "$#" -eq 2 ] && [ "$1" = -f ] && [ "$2" = /dev/kpanel-test-disk ] && fstype=xfs ;;
	mkfs.ntfs) [ "$#" -eq 2 ] && [ "$1" = -F ] && [ "$2" = /dev/kpanel-test-disk ] && fstype=ntfs ;;
	mkntfs) [ "$#" -eq 2 ] && [ "$1" = -F ] && [ "$2" = /dev/kpanel-test-disk ] && fstype=ntfs ;;
	mkfs.vfat) [ "$#" -eq 1 ] && [ "$1" = /dev/kpanel-test-disk ] && fstype=vfat ;;
	mkfs.fat) [ "$#" -eq 1 ] && [ "$1" = /dev/kpanel-test-disk ] && fstype=vfat ;;
	*) exit 87 ;;
esac || exit 88
printf '%s\n' "${fstype}" > "${MOCK_FSTYPE}"
MOCK_MKFS

cat > "${mock_bin}/mock-check" <<'MOCK_CHECK'
#!/bin/bash
set -u
name="${0##*/}"
printf '%s' "${name}" >> "${MOCK_LOG}"
printf '\t%s' "$@" >> "${MOCK_LOG}"
printf '\n' >> "${MOCK_LOG}"
[ "${MOCK_FAIL_COMMAND:-}" != "${name}" ] || exit 89
exit "${MOCK_CHECK_RC:-0}"
MOCK_CHECK

cat > "${mock_bin}/flock" <<'MOCK_FLOCK'
#!/bin/bash
set -u
printf 'flock' >> "${MOCK_LOG}"
printf '\t%s' "$@" >> "${MOCK_LOG}"
printf '\n' >> "${MOCK_LOG}"
[ "$#" -eq 4 ] && [ "$1" = -w ] && [ "$2" = 5 ] && [ "$3" = -x ] && [ "$4" = 9 ] || exit 90
[ "${MOCK_FLOCK_FAIL:-0}" != 1 ]
MOCK_FLOCK

cat > "${mock_bin}/chown" <<'MOCK_CHOWN'
#!/bin/bash
# Ownership changes are deliberately virtualized inside the temporary test tree.
exit 0
MOCK_CHOWN

cat > "${mock_bin}/sync" <<'MOCK_SYNC'
#!/bin/bash
[ "${MOCK_FAIL_COMMAND:-}" != sync ]
MOCK_SYNC

chmod +x "${mock_bin}"/*
for tool in mkfs.ext4 mkfs.xfs mkfs.ntfs mkntfs mkfs.vfat mkfs.fat; do
	cp -- "${mock_bin}/mock-mkfs" "${mock_bin}/${tool}"
done
for tool in e2fsck xfs_repair ntfsfix fsck.vfat fsck.fat; do
	cp -- "${mock_bin}/mock-check" "${mock_bin}/${tool}"
done
chmod +x "${mock_bin}"/*

export PATH="${mock_bin}:${PATH}"
export MOCK_LOG="${mock_log}" MOCK_MOUNTS="${mock_mounts}" MOCK_FSTYPE="${mock_fstype}"
export MOCK_VERIFY_LOG="${mock_verify_log}" MOCK_VERIFY_FAIL_POSTWRITE="${mock_verify_fail_postwrite}"

kpanel_disk_management_is_block_device() { [ "$1" = /dev/kpanel-test-disk ]; }
kpanel_disk_management_swaps_file() { printf '%s\n' "${mock_swaps}"; }
kpanel_disk_management_holders_dir() { printf '%s\n' "${mock_holders}"; }
kpanel_disk_management_fstab_file() { printf '%s\n' "${mock_fstab}"; }
kpanel_disk_management_state_root() { printf '%s\n' "${mock_state}"; }
kpanel_disk_management_lock_file() { printf '%s\n' "${mock_lock}"; }
kpanel_disk_management_lock_owner_uid() { id -u; }
kpanel_disk_management_require_platform() {
	KPANEL_DISK_MANAGEMENT_REQUIRE_MESSAGE=""
	[ "${KJ_DISK_MANAGEMENT_NONINTERACTIVE:-}" = 1 ] || {
		KPANEL_DISK_MANAGEMENT_REQUIRE_MESSAGE="protocol environment is disabled"
		return 2
	}
	kpanel_disk_management_require_commands \
		awk basename blkid chmod chown cp date dirname find findmnt flock grep lsblk mkdir mktemp \
		mount mv readlink rm rmdir sha256sum stat sync umount uname wc
}

kpanel_disk_management_path_owner_uid() { id -u; }
kpanel_disk_management_command_available() {
	case " ${MOCK_MISSING_TOOLS:-} " in
		*" $1 "*) return 1 ;;
	esac
	command -v "$1" >/dev/null 2>&1
}
kpanel_disk_management_path_stat_uid() {
	case "${test_root}" in
		"$1"|"$1"/*) id -u; return 0 ;;
	esac
	command stat -c '%u' "$1" 2>/dev/null
}
kpanel_disk_management_path_stat_mode() {
	if [ -n "${MOCK_UNSAFE_COMPONENT:-}" ] && [ "$1" = "${MOCK_UNSAFE_COMPONENT}" ]; then
		printf '777\n'
		return 0
	fi
	case "${test_root}" in
		"$1"/*) printf '755\n'; return 0 ;;
	esac
	command stat -c '%a' "$1" 2>/dev/null
}

reset_case() {
	: > "${mock_log}"
	: > "${mock_verify_log}"
	rm -f -- "${mock_verify_fail_postwrite}"
	rm -rf -- "${mock_state}"
	printf '0:1\t/\n' > "${mock_mounts}"
	printf 'ext4\n' > "${mock_fstype}"
	printf '# kpanel disk-management smoke\n' > "${mock_fstab}"
	chmod 644 "${mock_fstab}"
	unset MOCK_LSBLK_MODE MOCK_LSBLK_CHILD MOCK_DEVICE_RO MOCK_FINDMNT_READ_FAIL
	unset MOCK_BLKID_MODE MOCK_FAIL_COMMAND MOCK_CHECK_RC MOCK_FLOCK_FAIL
	unset MOCK_UNSAFE_COMPONENT MOCK_MISSING_TOOLS
}

run_receipt() {
	local expected_status="$1" expected_rc="$2"
	shift 2
	set +e
	(
		export KJ_DISK_MANAGEMENT_NONINTERACTIVE=1
		kpanel_disk_management_dispatch "$@"
	) > "${test_stdout}" 2> "${test_stderr}"
	local actual_rc=$?
	set -e
	[ "${actual_rc}" -eq "${expected_rc}" ] || fail "unexpected rc ${actual_rc}, expected ${expected_rc}: $*"
	mapfile -t receipt_lines < "${test_stdout}"
	[ "${#receipt_lines[@]}" -eq 5 ] || fail "receipt must contain exactly five lines: $*"
	[ "${receipt_lines[0]}" = 'KPANEL_DISK_MANAGEMENT_PROTOCOL 1' ] || fail "protocol header mismatch: $*"
	[ "${receipt_lines[1]}" = "KPANEL_DISK_MANAGEMENT_STATUS=${expected_status}" ] || fail "status mismatch: $*"
	[[ "${receipt_lines[2]}" =~ ^KPANEL_DISK_MANAGEMENT_DEVICE=([0-9]+:[0-9]+)?$ ]] || fail "device field mismatch: $*"
	[[ "${receipt_lines[3]}" =~ ^KPANEL_DISK_MANAGEMENT_MESSAGE_HEX=[0-9a-f]+$ ]] || fail "message hex mismatch: $*"
	[[ "${receipt_lines[4]}" =~ ^KPANEL_DISK_MANAGEMENT_BACKUP_HEX=[0-9a-f]*$ ]] || fail "backup hex mismatch: $*"
}

mount_hex() { kpanel_disk_management_hex_encode "$1"; }

reset_case
run_receipt failed 2 mount 8:1 zz 0
[ "${receipt_lines[2]}" = 'KPANEL_DISK_MANAGEMENT_DEVICE=8:1' ] || fail "valid requested MAJ:MIN was omitted from rejection receipt"
[ ! -s "${mock_log}" ] || fail "invalid hex reached an external disk command"
run_receipt failed 2 format 8:1 ext3
run_receipt failed 2 check broken readonly

protected_hex="$(mount_hex /home/kpanel-test)"
run_receipt failed 2 mount 8:1 "${protected_hex}" 0
if grep -q '^mount' "${mock_log}"; then fail "protected mountpoint reached mount"; fi

reset_case
unsafe_parent="${test_root}/unsafe-parent"
mkdir -- "${unsafe_parent}"
export MOCK_UNSAFE_COMPONENT="${unsafe_parent}"
run_receipt needs-attention 3 mount 8:1 "$(mount_hex "${unsafe_parent}/target")" 0
if grep -q '^mount' "${mock_log}"; then fail "group/world-writable mountpoint chain reached mount"; fi

reset_case
symlink_real="${test_root}/symlink-real"
symlink_parent="${test_root}/symlink-parent"
mkdir -- "${symlink_real}"
ln -s -- "${symlink_real}" "${symlink_parent}"
run_receipt failed 2 mount 8:1 "$(mount_hex "${symlink_parent}/target")" 0
if grep -q '^mount' "${mock_log}"; then fail "symlink mountpoint chain reached mount"; fi

reset_case
export MOCK_LSBLK_MODE=duplicate
duplicate_target="${test_root}/duplicate-target"
mkdir -- "${duplicate_target}"
run_receipt failed 1 mount 8:1 "$(mount_hex "${duplicate_target}")" 0
if grep -q '^mount' "${mock_log}"; then fail "duplicate MAJ:MIN resolution reached mount"; fi
export MOCK_LSBLK_MODE=malformed
run_receipt failed 1 format 8:1 ext4
if grep -q '^mkfs\.' "${mock_log}"; then fail "malformed lsblk output reached mkfs"; fi
export MOCK_LSBLK_MODE=fail
run_receipt failed 1 check 8:1 readonly
if grep -Eq '^(e2fsck|xfs_repair|ntfsfix|fsck\.vfat)' "${mock_log}"; then fail "failed lsblk reached checker"; fi

reset_case
mount_target="${test_root}/mount-existing"
mkdir -- "${mount_target}"
run_receipt applied 0 mount 8:1 "$(mount_hex "${mount_target}")" 0
assert_file_line "mount\t--source\t/dev/kpanel-test-disk\t--target\t${mount_target}" "${mock_log}"
run_receipt unchanged 0 mount 8:1 "$(mount_hex "${mount_target}")" 0
run_receipt applied 0 unmount 8:1 "$(mount_hex "${mount_target}")" 0
assert_file_line "umount\t--\t${mount_target}" "${mock_log}"

reset_case
nonempty_target="${test_root}/nonempty-target"
mkdir -- "${nonempty_target}"
printf 'keep\n' > "${nonempty_target}/user-data"
run_receipt needs-attention 3 mount 8:1 "$(mount_hex "${nonempty_target}")" 0
if grep -q '^mount' "${mock_log}"; then fail "nonempty mountpoint reached mount"; fi

reset_case
mount_failure_target="${test_root}/mount-failure-target"
mkdir -- "${mount_failure_target}"
export MOCK_FAIL_COMMAND=mount
run_receipt failed 1 mount 8:1 "$(mount_hex "${mount_failure_target}")" 0
if grep -Fqx 'KPANEL_DISK_MANAGEMENT_STATUS=applied' "${test_stdout}"; then
	fail "failed mount command was reported as applied"
fi

reset_case
persistent_target="${test_root}/persistent-target"
mkdir -- "${persistent_target}"
run_receipt applied 0 mount 8:1 "$(mount_hex "${persistent_target}")" 1
grep -Fqx "UUID=kpanel-test-uuid ${persistent_target} ext4 defaults,nofail 0 2" "${mock_fstab}" ||
	fail "persistent mount did not write the expected exact fstab entry"
[[ "${receipt_lines[4]}" =~ ^KPANEL_DISK_MANAGEMENT_BACKUP_HEX=[0-9a-f]+$ ]] || fail "persistent update omitted backup"
run_receipt applied 0 unmount 8:1 "$(mount_hex "${persistent_target}")" 1
if grep -Fq 'UUID=kpanel-test-uuid' "${mock_fstab}"; then fail "persistent unmount did not remove exact fstab entry"; fi

reset_case
unmount_rollback_target="${test_root}/unmount-rollback-target"
mkdir -- "${unmount_rollback_target}"
run_receipt applied 0 mount 8:1 "$(mount_hex "${unmount_rollback_target}")" 1
: > "${mock_verify_log}"
touch "${mock_verify_fail_postwrite}"
run_receipt failed 1 unmount 8:1 "$(mount_hex "${unmount_rollback_target}")" 1
grep -Fqx "UUID=kpanel-test-uuid ${unmount_rollback_target} ext4 defaults,nofail 0 2" "${mock_fstab}" ||
	fail "failed persistence removal did not restore fstab"
awk -F '\t' -v target="${unmount_rollback_target}" '$1 == "8:1" && $2 == target {found=1} END {exit found ? 0 : 1}' "${mock_mounts}" ||
	fail "failed persistence removal did not restore the live mount"

reset_case
rollback_target="${test_root}/rollback-created"
touch "${mock_verify_fail_postwrite}"
run_receipt failed 1 mount 8:1 "$(mount_hex "${rollback_target}")" 1
[ ! -e "${rollback_target}" ] || fail "fstab failure did not clean the newly created empty mountpoint"
if awk -F '\t' '$1 == "8:1" {found=1} END {exit found ? 0 : 1}' "${mock_mounts}"; then
	fail "fstab failure left the device mounted"
fi
[ "$(command cat -- "${mock_fstab}")" = '# kpanel disk-management smoke' ] || fail "fstab failure did not restore original content"
assert_file_line "mount\t--source\t/dev/kpanel-test-disk\t--target\t${rollback_target}" "${mock_log}"
assert_file_line "umount\t--\t${rollback_target}" "${mock_log}"
[[ "${receipt_lines[4]}" =~ ^KPANEL_DISK_MANAGEMENT_BACKUP_HEX=[0-9a-f]+$ ]] || fail "post-write fstab failure omitted recovery backup"

reset_case
for ((backup_index = 0; backup_index < 20; backup_index++)); do
	kpanel_disk_management_create_fstab_backup "${mock_fstab}" >/dev/null || fail "bounded backup creation failed"
done
backup_count="$(find "${mock_state}/recovery" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d '[:space:]')"
[ "${backup_count}" -eq 16 ] || fail "fstab recovery retention is not bounded to 16 snapshots"

reset_case
printf '8:1\t%s\n' "${test_root}/already-mounted" >> "${mock_mounts}"
run_receipt needs-attention 3 format 8:1 ext4
if grep -q '^mkfs\.ext4' "${mock_log}"; then fail "mounted device reached mkfs"; fi

for filesystem in ext4 xfs ntfs vfat; do
	reset_case
	run_receipt applied 0 format 8:1 "${filesystem}"
	case "${filesystem}" in
		ext4) expected="mkfs.ext4\t-F\t/dev/kpanel-test-disk" ;;
		xfs) expected="mkfs.xfs\t-f\t/dev/kpanel-test-disk" ;;
		ntfs) expected="mkfs.ntfs\t-F\t/dev/kpanel-test-disk" ;;
		vfat) expected="mkfs.vfat\t/dev/kpanel-test-disk" ;;
	esac
	assert_file_line "${expected}" "${mock_log}"
done

reset_case
export MOCK_MISSING_TOOLS=mkfs.ntfs
run_receipt applied 0 format 8:1 ntfs
assert_file_line 'mkntfs\t-F\t/dev/kpanel-test-disk' "${mock_log}"
if grep -q '^mkfs\.ntfs' "${mock_log}"; then fail "ntfs fallback called unavailable primary command"; fi

reset_case
export MOCK_MISSING_TOOLS=mkfs.vfat
run_receipt applied 0 format 8:1 vfat
assert_file_line 'mkfs.fat\t/dev/kpanel-test-disk' "${mock_log}"
if grep -q '^mkfs\.vfat' "${mock_log}"; then fail "fat fallback called unavailable primary command"; fi

for specification in \
	'ext4 readonly e2fsck\t-fn\t/dev/kpanel-test-disk unchanged 0' \
	'ext4 repair e2fsck\t-fy\t/dev/kpanel-test-disk applied 0' \
	'xfs readonly xfs_repair\t-n\t/dev/kpanel-test-disk unchanged 0' \
	'xfs repair xfs_repair\t/dev/kpanel-test-disk applied 0' \
	'ntfs readonly ntfsfix\t-n\t/dev/kpanel-test-disk unchanged 0' \
	'ntfs repair ntfsfix\t/dev/kpanel-test-disk applied 0' \
	'vfat readonly fsck.vfat\t-n\t/dev/kpanel-test-disk unchanged 0' \
	'vfat repair fsck.vfat\t-a\t/dev/kpanel-test-disk applied 0'; do
	read -r filesystem mode expected status rc <<< "${specification}"
	reset_case
	printf '%s\n' "${filesystem}" > "${mock_fstype}"
	run_receipt "${status}" "${rc}" check 8:1 "${mode}"
	assert_file_line "${expected}" "${mock_log}"
done

reset_case
printf 'vfat\n' > "${mock_fstype}"
export MOCK_MISSING_TOOLS=fsck.vfat
run_receipt unchanged 0 check 8:1 readonly
assert_file_line 'fsck.fat\t-n\t/dev/kpanel-test-disk' "${mock_log}"
if grep -q '^fsck\.vfat' "${mock_log}"; then fail "fat checker fallback called unavailable primary command"; fi

reset_case
printf 'vfat\n' > "${mock_fstype}"
export MOCK_MISSING_TOOLS=fsck.vfat
run_receipt applied 0 check 8:1 repair
assert_file_line 'fsck.fat\t-a\t/dev/kpanel-test-disk' "${mock_log}"

reset_case
export MOCK_FAIL_COMMAND=mkfs.ext4
run_receipt failed 1 format 8:1 ext4
if grep -Fqx 'KPANEL_DISK_MANAGEMENT_STATUS=applied' "${test_stdout}"; then
	fail "failed mkfs was reported as applied"
fi

reset_case
export MOCK_FAIL_COMMAND=e2fsck
run_receipt needs-attention 3 check 8:1 readonly
if grep -Fqx 'KPANEL_DISK_MANAGEMENT_STATUS=unchanged' "${test_stdout}"; then
	fail "failed readonly checker was reported as unchanged"
fi

reset_case
export MOCK_FLOCK_FAIL=1
run_receipt conflict 2 format 8:1 ext4
if grep -q '^mkfs\.ext4' "${mock_log}"; then fail "lock conflict reached mkfs"; fi

reset_case
rm -f -- "${mock_lock}"
lock_hardlink_source="${mock_lock_parent}/hardlink-source"
: > "${lock_hardlink_source}"
chmod 600 "${lock_hardlink_source}"
ln -- "${lock_hardlink_source}" "${mock_lock}"
run_receipt failed 1 format 8:1 ext4
if grep -q '^mkfs\.ext4' "${mock_log}"; then fail "hard-linked lock reached mkfs"; fi

printf '%s\n' 'PASS: KPanel disk-management noninteractive smoke tests'
