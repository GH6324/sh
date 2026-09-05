#!/usr/bin/env python3
"""Run the authoritative updater in an isolated filesystem with real processes.

Requires Linux/root for the installer UID/GID boundary. No host service or network
is touched: curl/systemctl are fixtures and all fixed paths point into TemporaryDirectory.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import unittest

SOURCE = Path(os.environ.get('SCRIPT_PATH', Path(__file__).resolve().parents[1] / 'kejilion.sh')).read_text()
UPDATER = SOURCE.split("<<'KPANEL_NODE_UPDATE'\n", 1)[1].split('\nKPANEL_NODE_UPDATE\n', 1)[0]
FILE_UNIT = UPDATER.split("<<'KPANEL_NODE_FILE_SERVICE'\n", 1)[1].split('\nKPANEL_NODE_FILE_SERVICE\n', 1)[0] + '\n'
# Verbatim installer-owned unit from kejilion/sh@2ee9856c9916b7ede8bbc19edc97e22872e86203.
LEGACY_FILE_UNIT = (Path(__file__).resolve().parent / 'fixtures/kpanel-node-file-2ee9856.service').read_text()

CURL = r'''#!/usr/bin/python3
import json,os,pathlib,shutil,sys
root=pathlib.Path(os.environ['NODE_TEST_ROOT']); args=sys.argv[1:]
with (root/'downloads').open('a') as f: f.write(args[-1]+'\n')
assert '--retry' in args and '--retry-max-time' in args and '--max-filesize' in args
assert args[args.index('--proto-redir')+1]=='=https'
if (root/'network-down').exists(): sys.exit(7)
out=pathlib.Path(args[args.index('-o')+1])
if args[-1].endswith('/SHA256SUMS'):
 shutil.copyfile(root/'SHA256SUMS',out)
 pathlib.Path(args[args.index('--dump-header')+1]).write_text('HTTP/2 302\r\nLocation: https://github.com/kejilion/KPanel/releases/download/v9.9.9/SHA256SUMS\r\n\r\nHTTP/2 302\r\nlocation: https://release-assets.githubusercontent.com/test\r\n\r\n')
else:
 assert args[-1]=='https://github.com/kejilion/KPanel/releases/download/v9.9.9/kejilion-node-linux-amd64'
 shutil.copyfile(root/('bad' if (root/'bad-download').exists() else 'release'),out)
'''

SYSTEMCTL = r'''#!/usr/bin/python3
import hashlib,json,os,pathlib,signal,subprocess,sys
root=pathlib.Path(os.environ['NODE_TEST_ROOT']); args=sys.argv[1:]
service=next((a for a in args if a.endswith('.service')), '')
with (root/'calls').open('a') as f: f.write(' '.join(args)+'\n')
pidfile=root/(service+'.pid')
pid=int(pidfile.read_text()) if pidfile.exists() else 0
if args[0] in ('daemon-reload','enable'): sys.exit(0)
if args[0]=='cat': sys.exit(0 if service=='kejilion-node.service' or (root/'optional').exists() else 1)
if args[0]=='show': print(pid); sys.exit(0)
if args[0]=='is-active':
 try:
  os.kill(pid,0)
  alive=pid>0 and pathlib.Path('/proc/%d/exe'%pid).exists()
 except OSError: alive=False
 sys.exit(0 if alive else 3)
if args[0]=='restart':
 if pid:
  try: os.killpg(pid,signal.SIGKILL)
  except ProcessLookupError: pass
  pidfile.unlink(missing_ok=True)
 if service!='kejilion-node.service' and (root/'optional-fail').exists(): sys.exit(1)
 binary=root/'home/kejilion-node'
 if service=='kejilion-node.service' and (root/'core-fail').exists() and binary.read_bytes()==(root/'release').read_bytes(): sys.exit(1)
 if service=='kejilion-node.service':
  # Exercise the actual unprivileged read of the rewritten/repaired credential.
  check=subprocess.run(['/bin/cat',str(root/'config/node.json')],user=65534,group=65534,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
  if check.returncode: sys.exit(1)
 command=[str(binary),'-c','while :; do sleep 30; done']
 if (root/'delayed-exec').exists():
  import shlex
  command=['/bin/sh','-c','sleep 0.5; exec '+shlex.join(command)]
 p=subprocess.Popen(command,stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True,close_fds=True)
 pidfile.write_text(str(p.pid)); sys.exit(0)
sys.exit(1)
'''

@unittest.skipUnless(sys.platform.startswith('linux') and os.geteuid() == 0, 'requires isolated Linux root')
class NodeUpdater(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='kpanel-update-test-')
        self.root = Path(self.temp.name)
        self.root.chmod(0o755)
        for name in ('home', 'config', 'units', 'bin'):
            (self.root / name).mkdir()
        os.chown(self.root / 'config', 0, 65534)
        (self.root / 'config').chmod(0o750)
        config = self.root / 'config/node.json'
        config.write_text('{"schemaVersion":1}')
        config.chmod(0o640)
        os.chown(config, 0, 65534)
        self.binary = self.root / 'home/kejilion-node'
        shutil.copyfile('/bin/dash', self.binary)
        self.binary.chmod(0o755)
        shutil.copyfile('/bin/bash', self.root / 'release')
        (self.root / 'version').write_text('echo "9.9.9 light-v1"\n')
        (self.root / 'bad').write_text('corrupt')
        digest = hashlib.sha256((self.root / 'release').read_bytes()).hexdigest()
        (self.root / 'SHA256SUMS').write_text(digest + '  kejilion-node-linux-amd64\n')
        for name, content in [('curl', CURL), ('systemctl', SYSTEMCTL), ('id', '#!/bin/sh\ncase "$1" in -g) echo 65534;; -gn) echo kejilion-node;; *) /usr/bin/id "$@";; esac\n')]:
            (self.root / 'bin' / name).write_text(content)
            (self.root / 'bin' / name).chmod(0o755)
        script = UPDATER.replace('/usr/local/lib/kejilion-node', str(self.root / 'home')).replace('/etc/kejilion-node', str(self.root / 'config')).replace('/etc/systemd/system', str(self.root / 'units')).replace('/run/lock/kejilion-node-update.lock', str(self.root / 'legacy.lock'))
        (self.root / 'update.sh').write_text(script)
        self.env = {**os.environ, 'NODE_TEST_ROOT': str(self.root), 'PATH': str(self.root / 'bin') + ':' + os.environ['PATH']}

    def tearDown(self):
        for path in self.root.glob('*.service.pid'):
            try: os.killpg(int(path.read_text()), signal.SIGKILL)
            except ProcessLookupError: pass
        self.temp.cleanup()

    def run_update(self, success=True):
        result = subprocess.run(['/bin/bash', str(self.root / 'update.sh'), 'update'], cwd=self.root, env=self.env, text=True, capture_output=True, timeout=20)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def test_upgrade_optional_failure_does_not_rollback_and_delayed_exec_is_accepted(self):
        (self.root / 'optional').touch()
        (self.root / 'optional-fail').touch()
        (self.root / 'delayed-exec').touch()
        result = self.run_update()
        self.assertIn('optional service unavailable', result.stderr)
        self.assertEqual(self.binary.read_bytes(), (self.root / 'release').read_bytes())
        self.assertFalse((self.root / 'home/kejilion-node.previous').exists())

    def test_failed_core_rolls_back_and_restart_failure_cannot_be_masked(self):
        before = self.binary.read_bytes()
        (self.root / 'core-fail').touch()
        result = self.run_update(False)
        self.assertIn('was rolled back', result.stderr)
        self.assertEqual(self.binary.read_bytes(), before)

    def test_current_file_with_old_process_recovers_without_binary_download(self):
        subprocess.run([str(self.root / 'bin/systemctl'), 'restart', 'kejilion-node.service'], env=self.env, check=True)
        # Atomic replacement leaves the service running the previous inode.
        shutil.copyfile(self.root / 'release', self.root / 'home/new')
        (self.root / 'home/new').chmod(0o755)
        os.replace(self.root / 'home/new', self.binary)
        self.run_update()
        pid = int((self.root / 'kejilion-node.service.pid').read_text())
        self.assertTrue(os.path.samefile('/proc/%d/exe' % pid, self.binary))
        self.assertEqual(len((self.root / 'downloads').read_text().splitlines()), 1)

    def test_legacy_config_permissions_recover_for_real_service_uid(self):
        config = self.root / 'config/node.json'
        os.chown(config, 0, 0)
        config.chmod(0o600)
        self.run_update()
        self.assertEqual(config.stat().st_gid, 65534)
        self.assertEqual(config.stat().st_mode & 0o777, 0o640)

    def test_known_legacy_file_unit_is_repaired_and_current_broker_restarts(self):
        (self.root / 'optional').touch()
        self.run_update()
        unit = self.root / 'units/kejilion-node-file.service'
        current = unit.read_text()
        legacy = current.replace('RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6', 'RestrictAddressFamilies=AF_UNIX')
        self.assertNotEqual(current, legacy)
        unit.write_text(legacy)
        old_pid = (self.root / 'kejilion-node-file.service.pid').read_text()
        self.run_update()
        self.assertEqual(unit.read_text(), current)
        self.assertNotEqual((self.root / 'kejilion-node-file.service.pid').read_text(), old_pid)

    def test_custom_and_symlink_file_units_are_preserved(self):
        unit = self.root / 'units/kejilion-node-file.service'
        custom = '[Service]\nExecStart=/custom/broker\nRestrictAddressFamilies=AF_UNIX\n'
        unit.write_text(custom)
        self.run_update()
        self.assertEqual(unit.read_text(), custom)
        unit.unlink()
        target = self.root / 'private-unit'
        target.write_text(custom)
        unit.symlink_to(target)
        self.run_update()
        self.assertTrue(unit.is_symlink())
        self.assertEqual(target.read_text(), custom)

    def test_original_historical_file_unit_migrates_but_custom_variant_is_preserved(self):
        self.assertEqual(hashlib.sha256(LEGACY_FILE_UNIT.encode()).hexdigest(), 'b92a708103771a8e1334b74acc44c1c7299b8339f8ca36884e1084e86642f92d')
        (self.root / 'optional').touch()
        self.run_update()
        unit = self.root / 'units/kejilion-node-file.service'
        current = unit.read_text()
        legacy = LEGACY_FILE_UNIT.replace('/usr/local/lib/kejilion-node', str(self.root / 'home')).replace('/etc/kejilion-node', str(self.root / 'config'))
        unit.write_text(legacy)
        old_pid = (self.root / 'kejilion-node-file.service.pid').read_text()
        self.run_update()
        self.assertEqual(unit.read_text(), current)
        self.assertNotEqual((self.root / 'kejilion-node-file.service.pid').read_text(), old_pid)
        custom = legacy.replace('RestartSec=15s', 'RestartSec=30s')
        unit.write_text(custom)
        self.run_update()
        self.assertEqual(unit.read_text(), custom)

    def test_bad_checksum_and_network_failure_preserve_binary_then_retry_recovers(self):
        before = self.binary.read_bytes()
        (self.root / 'bad-download').touch()
        self.run_update(False)
        self.assertEqual(self.binary.read_bytes(), before)
        (self.root / 'bad-download').unlink()
        (self.root / 'network-down').touch()
        self.run_update(False)
        self.assertEqual(self.binary.read_bytes(), before)
        (self.root / 'network-down').unlink()
        self.run_update()

    def test_sigkill_releases_lock_and_legacy_handoff_blocks_only_live_process(self):
        (self.root / 'legacy.lock').mkdir()
        self.assertIn('legacy KPanel update lock', self.run_update(False).stderr)
        (self.root / 'legacy.lock').rmdir()
        process = subprocess.Popen(['flock', str(self.root / 'home/update.lock'), '/bin/sleep', '60'], start_new_session=True)
        try:
            import time
            time.sleep(0.1)
            self.run_update(False)
        finally:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        stat = Path('/proc/%d/stat' % os.getpid()).read_text().rsplit(')', 1)[1].split()
        marker = self.root / 'home/legacy-update.pid'
        marker.write_text('%d %s\n' % (os.getpid(), stat[19]))
        self.assertIn('still finishing', self.run_update(False).stderr)
        # A reused PID with a different start time cannot block future checks.
        marker.write_text('%d 0\n' % os.getpid())
        self.run_update()

    def test_unsafe_config_is_rejected_without_widening_permissions(self):
        config = self.root / 'config/node.json'
        config.chmod(0o666)
        self.run_update(False)
        self.assertEqual(config.stat().st_mode & 0o777, 0o666)


if __name__ == '__main__':
    unittest.main(verbosity=2)
