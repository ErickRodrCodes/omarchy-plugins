"""Offline safety and regression tests. Never load a compositor plugin."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('control', Path(__file__).with_name('control.py'))
c = importlib.util.module_from_spec(spec); spec.loader.exec_module(c)
spec = importlib.util.spec_from_file_location('input_layout', Path(__file__).parents[1]/'recovery/input_layout.py')
i = importlib.util.module_from_spec(spec); spec.loader.exec_module(i)
ROW = [dict(name='Dell',x=4864,y=0,width=1920,height=1080,scale=1),dict(name='ASUS',x=0,y=0,width=3840,height=2160,scale=1),dict(name='Elgato',x=3840,y=0,width=1024,height=600,scale=1)]
GOOD = 'Dell connected 1920x1080+4864+0\nASUS connected primary 3840x2160+0+0\nElgato connected 1024x600+3840+0'
BAD = 'Dell connected 1920x1080+0+0\nASUS connected 3840x2160+1920+0\nElgato connected 1024x600+5760+0'

class InputTests(unittest.TestCase):
    def test_actual_dell_regression(self):
        self.assertFalse(i.compare(ROW,BAD)[0])
        self.assertTrue(i.compare(ROW,GOOD)[0])
    def test_incomplete_and_unknown_output_fail_closed(self):
        for text in ('', GOOD.splitlines()[0], GOOD+'\nExtra connected 800x600+6784+0'):
            self.assertFalse(i.compare(ROW,text)[0])
    def test_native_row_limits(self):
        c.validate_row(ROW)
        for field,value in [('x',3840),('scale',2),('transform',1)]:
            bad=[dict(m) for m in ROW];bad[0][field]=value
            with self.assertRaises(RuntimeError):c.validate_row(bad)
    def test_running_horizon_blocks_enable_and_disable(self):
        def refuse():raise RuntimeError('Horizon running')
        for action in (c.activate,c.deactivate):
            with patch.object(c.runpy,'run_path',return_value={'require_horizon_closed':refuse}),patch.object(c,'run') as run,patch.object(c,'build') as build:
                with self.assertRaisesRegex(RuntimeError,'running'):action()
                run.assert_not_called();build.assert_not_called()
    def test_version_mismatch_blocks_build(self):
        with patch.object(c.runpy,'run_path',return_value={'require_horizon_closed':lambda:None, 'geometry':i.geometry}),patch.object(c,'run',return_value=json.dumps({'commit':'unknown'})),patch.object(c,'build') as build:
            with self.assertRaisesRegex(RuntimeError,'Unsupported'):c.activate()
            build.assert_not_called()
    def test_enable_verifies_and_rolls_back_failure(self):
        for success in (True,False):
            with self.subTest(success=success),tempfile.TemporaryDirectory() as directory:
                state=Path(directory); calls=[]
                def run(*args):
                    calls.append(args)
                    if args==('hyprctl','-j','version'):return json.dumps({'commit':c.SUPPORTED,'dirty':False})
                    if args==('hyprctl','-j','monitors'):return json.dumps(ROW)
                    if args==('xrandr','--query'):return BAD
                    return 'ok'
                def build(path):
                    p=Path(path)/'test.so';p.write_bytes(b'test');return p
                with patch.object(c,'STATE',state),patch.object(c,'record',return_value=state/'record.json'),patch.object(c,'run',side_effect=run),patch.object(c,'build',side_effect=build),patch.object(c,'active',side_effect=[False,True]+([] if success else [False])),patch.object(c,'check_layout',return_value=(success,'mismatch')),patch.object(c.time,'sleep'),patch.object(c.runpy,'run_path',return_value={'require_horizon_closed':lambda:None, 'geometry':i.geometry}):
                    if success:self.assertIn('corrected',c.activate())
                    else:
                        with self.assertRaisesRegex(RuntimeError,'converge'):c.activate()
                self.assertEqual(any(args[:3]==('hyprctl','plugin','unload') for args in calls),not success)
                self.assertEqual((state/'record.json').exists(),success)

if __name__=='__main__':unittest.main()
