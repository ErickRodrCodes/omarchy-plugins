"""Exercise the real launch wrapper with fake display tools and a fake client."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).parents[1]
ROW=[dict(name='Dell',x=4864,y=0,width=1920,height=1080,disabled=False),dict(name='ASUS',x=0,y=0,width=3840,height=2160,disabled=False),dict(name='Elgato',x=3840,y=0,width=1024,height=600,disabled=False)]
class LauncherTests(unittest.TestCase):
    def test_native_bypasses_override_and_legacy_retains_it(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);bin=root/'bin';bin.mkdir()
            plugin=root/'plugin';shutil.copytree(ROOT/'recovery/plugin',plugin)
            def stub(name,code):
                p=bin/name;p.write_text('#!'+sys.executable+'\n'+code+'\n');p.chmod(0o755)
            stub('hyprctl','print('+repr(json.dumps(ROW))+')')
            stub('xrandr',"import os\nprint(os.environ['TEST_RANDR'])")
            stub('horizon-client',"import os,json,sys\nprint(json.dumps({'layout':os.environ.get('HORIZON_DISPLAY_LAYOUT'),'preload':os.environ.get('LD_PRELOAD'),'signature':os.environ.get('HORIZON_LAYOUT_SIGNATURE'),'args':sys.argv[1:]}))")
            env={**os.environ,'HOME':str(root),'XDG_STATE_HOME':str(root/'state'),'PATH':str(bin)+os.pathsep+os.environ['PATH']}
            env.pop('LD_PRELOAD',None);env.pop('HORIZON_DISPLAY_LAYOUT',None)
            command=[str(plugin/'scripts/horizon-display-layout'),'launch','--argument','value with spaces']
            env['TEST_RANDR']='Dell connected 1920x1080+0+0\nASUS connected 3840x2160+1920+0\nElgato connected 1024x600+5760+0'
            legacy=json.loads(subprocess.check_output(command,env=env,text=True))
            self.assertIn('4864',legacy['layout']);self.assertIn('libhorizon-display-layout.so',legacy['preload'])
            env['TEST_RANDR']='Dell connected 1920x1080+4864+0\nASUS connected 3840x2160+0+0\nElgato connected 1024x600+3840+0'
            # A shell launched from an old wrapper can inherit its override.
            env['LD_PRELOAD']=legacy['preload'];env['HORIZON_DISPLAY_LAYOUT']=legacy['layout']
            native=json.loads(subprocess.check_output(command,env=env,text=True))
            self.assertIsNotNone(native['signature']);self.assertEqual(native['signature'],legacy['signature'])
            self.assertIsNone(native['layout']);self.assertIsNone(native['preload'])
            self.assertEqual(native['args'],['--argument','value with spaces'])

if __name__=='__main__':unittest.main()
