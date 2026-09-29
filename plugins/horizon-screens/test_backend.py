import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

loader = importlib.machinery.SourceFileLoader('backend', str(Path(__file__).with_name('backend')))
spec = importlib.util.spec_from_loader(loader.name, loader)
b = importlib.util.module_from_spec(spec)
loader.exec_module(b)

class BackendTests(unittest.TestCase):
    def test_restore_requires_saved_selection(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(b, 'CONFIG', Path(directory)/'missing'), patch('sys.argv', ['backend','restore']), patch.object(b.subprocess, 'run') as run:
            with self.assertRaisesRegex(RuntimeError, 'Review and save'):
                b.main()
            run.assert_not_called()

    def test_selection_paths_validate_and_preserve_user_choice(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            user=root/'user'; user.mkdir()
            system=root/'system'; system.mkdir()
            desktop=user/'custom.desktop'
            desktop.write_text('[Desktop Entry]\nExec=horizon-client %u\n')
            with patch.object(b,'USER_APPS',user), patch.object(b,'SYSTEM_APPS',system), patch.object(b,'CONFIG',root/'config/launchers.json'):
                self.assertEqual(b.launcher_paths(),[str(desktop)])
                with patch('sys.argv',['backend','save-launchers',json.dumps([str(desktop)])]):
                    self.assertTrue(b.main()['ok'])
                self.assertEqual(b.launcher_paths(),[str(desktop)])
                self.assertEqual(desktop.read_text(),'[Desktop Entry]\nExec=horizon-client %u\n')
                with self.assertRaises(RuntimeError):b.validate_launchers([str(root/'not-allowed.desktop')])
                with self.assertRaises(RuntimeError):b.validate_launchers([str(desktop),str(desktop)])

    def test_action_passes_only_saved_selection(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory); desktop=root/'horizon.desktop'
            desktop.write_text('Exec=horizon-client %u\n')
            config=root/'config.json'; config.write_text(json.dumps([str(desktop)]))
            with patch.object(b,'CONFIG',config),patch.object(b,'USER_APPS',root),patch('sys.argv',['backend','restore']),patch.object(b.subprocess,'run') as run:
                run.return_value.returncode=1
                run.return_value.stdout=''
                run.return_value.stderr='Fully quit Horizon'
                result=b.main()
                self.assertFalse(result['ok'])
                self.assertIn('Fully quit',result['message'])
                self.assertEqual(json.loads(run.call_args.kwargs['env']['HORIZON_RECOVERY_LAUNCHERS']),[str(desktop)])

if __name__=='__main__':unittest.main()
