"""Offline tests. No desktop access, real Horizon launch, or home-directory writes."""
import contextlib
import copy
import importlib.machinery
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

loader = importlib.machinery.SourceFileLoader('recovery', str(Path(__file__).with_name('fix-horizon-screens')))
spec = importlib.util.spec_from_loader(loader.name, loader)
r = importlib.util.module_from_spec(spec)
loader.exec_module(r)

MONITORS = [dict(x=4864, y=0, width=1920, height=1080, scale=1),
            dict(x=0, y=0, width=3840, height=2160, scale=1),
            dict(x=3840, y=0, width=1024, height=600, scale=1)]
WINDOW = dict(address='0xabc', pid=123, mapped=True, floating=True,
              size=[6784, 2160], at=[-1920, 0], fullscreen=0)
ENV = b'HORIZON_DISPLAY_LAYOUT=test\0LD_PRELOAD=/tmp/libhorizon-display-layout.so\0'


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        session_patch = patch.object(r, 'session_layout', return_value=(True, 'matched'))
        session_patch.start()
        self.addCleanup(session_patch.stop)
        input_patch = patch.object(r, 'input_layout', return_value=(True, 'matched'))
        input_patch.start()
        self.addCleanup(input_patch.stop)
        self.output = contextlib.redirect_stdout(io.StringIO())
        self.output.__enter__()
        self.addCleanup(self.output.__exit__, None, None, None)

    def test_geometry_and_negative_origin(self):
        self.assertEqual(r.geometry(MONITORS), (0, 0, 6784, 2160))
        shifted = [dict(m, x=m['x'] - 3840) for m in MONITORS]
        self.assertEqual(r.geometry(shifted), (-3840, 0, 6784, 2160))

    def test_unsupported_layouts(self):
        for monitors in ([dict(m, scale=2) for m in MONITORS],
                         [dict(m, transform=1) for m in MONITORS],
                         [dict(m, disabled=True) for m in MONITORS]):
            with self.subTest(monitors=monitors), self.assertRaises(RuntimeError):
                r.geometry(monitors)

    def test_move_is_absolute_and_verified(self):
        after = dict(WINDOW, at=[0, 0])
        with patch.object(r, 'displays', return_value=(0, 0, 6784, 2160)), \
             patch.object(r, 'clients', side_effect=[[WINDOW], [after]]), \
             patch.object(Path, 'read_bytes', return_value=ENV), \
             patch.object(r, 'run', return_value='ok') as run:
            r.fix()
            run.assert_called_once_with('hyprctl', 'dispatch',
                'hl.dsp.window.move({ window = "address:0xabc", x = 0, y = 0 })')

    def test_aligned_and_dry_run_do_not_dispatch(self):
        for window, dry in [(dict(WINDOW, at=[0, 0]), False), (WINDOW, True)]:
            with patch.object(r, 'displays', return_value=(0, 0, 6784, 2160)), \
                 patch.object(r, 'clients', return_value=[window]), \
                 patch.object(Path, 'read_bytes', return_value=ENV), \
                 patch.object(r, 'run') as run:
                r.fix(dry)
                run.assert_not_called()

    def test_unsafe_windows_do_not_dispatch(self):
        for windows in ([], [WINDOW, WINDOW], [dict(WINDOW, size=[3840, 2160])],
                        [dict(WINDOW, fullscreen=2)], [dict(WINDOW, floating=False)]):
            with patch.object(r, 'displays', return_value=(0, 0, 6784, 2160)), \
                 patch.object(r, 'clients', return_value=windows), \
                 patch.object(r, 'run') as run, self.assertRaises(RuntimeError):
                r.fix()
            run.assert_not_called()

    def test_mismatched_input_layout_refuses_move(self):
        with patch.object(r, 'displays', return_value=(0, 0, 6784, 2160)), \
             patch.object(r, 'clients', return_value=[WINDOW]), \
             patch.object(r, 'input_layout', return_value=(False, 'Input mismatch')), \
             patch.object(r, 'run') as run, self.assertRaises(RuntimeError):
            r.fix()
        run.assert_not_called()

    def test_changed_launch_layout_refuses_alignment(self):
        with patch.object(r, 'displays', return_value=(0, 0, 6784, 2160)), \
             patch.object(r, 'clients', return_value=[WINDOW]), \
             patch.object(r, 'session_layout', return_value=(False, 'Reconnect')), \
             patch.object(r, 'run') as run, self.assertRaisesRegex(RuntimeError, 'Reconnect'):
            r.fix()
        run.assert_not_called()

    def test_running_client_blocks_restore_before_writes(self):
        with patch.object(r, 'running_horizon_pids', return_value=['123']), \
             patch.object(r, 'displays') as displays, \
             patch.object(r.shutil, 'copytree') as copytree, self.assertRaises(RuntimeError):
            r.restore()
        displays.assert_not_called()
        copytree.assert_not_called()

    def test_visible_window_also_blocks_verify(self):
        with patch.object(r, 'running_horizon_pids', return_value=[]), \
             patch.object(r, 'clients', return_value=[WINDOW]), \
             patch.object(r, 'run') as run, \
             patch('sys.argv', ['fix-horizon-screens', 'verify']), self.assertRaises(RuntimeError):
            r.main()
        run.assert_not_called()

    def test_failed_move_is_not_reported_as_success(self):
        with patch.object(r, 'displays', return_value=(0, 0, 6784, 2160)), \
             patch.object(r, 'clients', return_value=[WINDOW]), \
             patch.object(Path, 'read_bytes', return_value=ENV), \
             patch.object(r, 'run', return_value='ok'), self.assertRaises(RuntimeError):
            r.fix()

    def test_restore_in_temporary_directory_preserves_arguments_and_backups(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'plugin').mkdir()
            (root / 'plugin/marker').write_text('bundled')
            plugin = root / 'installed'
            plugin.mkdir()
            (plugin / 'marker').write_text('original')
            apps = root / 'apps'
            apps.mkdir()
            desktop = apps / 'horizon-client.desktop'
            original = '[Desktop Entry]\nExec=env GDK_SCALE=1 horizon-client %u\n[Desktop Action about]\nExec=horizon-client --about --useExisting\n'
            desktop.write_text(original)
            untouched = apps / 'other.desktop'
            untouched.write_text('[Desktop Entry]\nExec=other %u\n')
            state = root / 'state/horizon-display-layout'
            state.mkdir(parents=True)
            (state / 'libhorizon-display-layout.so').write_bytes(b'old')

            def fake_subprocess(args, **kwargs):
                if args[0] == 'cc':
                    Path(args[args.index('-o') + 1]).write_bytes(b'compiled')
                elif args[0] != 'update-desktop-database':
                    raise AssertionError(args)

            with patch.object(r, 'ROOT', root), patch.object(r, 'PLUGIN', plugin), \
                 patch.object(r, 'HELPER', plugin / 'scripts/horizon-display-layout'), \
                 patch.object(r, 'APPS', apps), patch.object(r, 'require_horizon_closed'), \
                 patch.object(r, 'displays'), patch.object(r.shutil, 'which', return_value='/mock/bin'), \
                 patch.dict(r.os.environ, {'XDG_STATE_HOME': str(root / 'state')}), \
                 patch.object(r.subprocess, 'run', side_effect=fake_subprocess), \
                 patch.object(r, 'run', return_value='VERIFIED'):
                r.restore()
                first = desktop.read_text()
                r.restore()
                self.assertEqual(desktop.read_text(), first)
            self.assertIn('launch %u', first)
            self.assertIn('launch --about --useExisting', first)
            self.assertEqual(untouched.read_text(), '[Desktop Entry]\nExec=other %u\n')
            backups = sorted((root / 'backups').iterdir())
            self.assertEqual((backups[0] / 'horizon-client.desktop').read_text(), original)
            self.assertEqual((backups[0] / 'plugin/marker').read_text(), 'original')
            self.assertEqual((backups[0] / 'libhorizon-display-layout.so').read_bytes(), b'old')
            self.assertEqual((state / 'libhorizon-display-layout.so').read_bytes(), b'compiled')


if __name__ == '__main__':
    unittest.main()
