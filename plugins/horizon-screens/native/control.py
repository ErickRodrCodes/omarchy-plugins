#!/usr/bin/env python3
"""Build/test or explicitly enable the session-only input-layout correction."""
import hashlib
import json
import os
from pathlib import Path
import re
import runpy
import shlex
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parent
STATE = Path(os.environ.get('XDG_STATE_HOME', str(Path.home()/'.local/state'))) / 'horizon-screens/native'
NAME = 'horizon-input-layout'
SUPPORTED = 'efb50993780079460b0cbed1363e2166a2de1d9f'
RECOVERY = ROOT.parent / 'recovery/fix-horizon-screens'

def run(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.PIPE, timeout=60).strip()

def check_layout():
    monitors = json.loads(run('hyprctl', '-j', 'monitors'))
    compare = runpy.run_path(str(ROOT.parent/'recovery/input_layout.py'))['compare']
    return compare(monitors, run('xrandr', '--query'))

def validate_row(monitors):
    # Keep the public helper name for existing callers; the model is no longer a row.
    runpy.run_path(str(ROOT.parent/'recovery/input_layout.py'))['geometry'](monitors)


def build(directory):
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    flags = shlex.split(run('pkg-config', '--cflags', 'hyprland'))
    header = Path('/usr/include/hyprland/src/version.h').read_text()
    commit = re.search(r'#define GIT_COMMIT_HASH\s+"([a-f0-9]+)"', header)
    if not commit or commit[1] != SUPPORTED:
        raise RuntimeError('Unsupported Hyprland headers. Review the native hook before rebuilding for a new version.')
    for command in (
        ['g++','-std=c++23','-O2','-Wall','-Wextra','-shared','-fPIC',*flags,str(ROOT/'plugin.cpp'),'-o',str(directory/f'{NAME}.so')],
        ['g++','-std=c++23','-Wall','-Wextra','-Werror',str(ROOT/'test_layout.cpp'),'-o',str(directory/'test_layout')],
        [str(directory/'test_layout')],
    ):
        subprocess.run(command, check=True, capture_output=True, text=True, timeout=120)
    return directory/f'{NAME}.so'

def active():
    return any(p.get('name') == NAME for p in json.loads(run('hyprctl','-j','plugin','list')))

def record():
    instance = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')
    if not instance: raise RuntimeError('No active Hyprland session.')
    return STATE / (hashlib.sha256(instance.encode()).hexdigest()[:16]+'.json')

def activate():
    guard = runpy.run_path(str(RECOVERY))['require_horizon_closed']
    guard()  # before compilation or state writes
    version = json.loads(run('hyprctl','-j','version'))
    if version.get('commit') != SUPPORTED or version.get('dirty'):
        raise RuntimeError('Unsupported Hyprland build; input repair was not loaded.')
    validate_row(json.loads(run('hyprctl','-j','monitors')))
    if active():
        info = next(p for p in json.loads(run('hyprctl','-j','plugin','list')) if p.get('name') == NAME)
        if info.get('version') != '0.2.0':
            raise RuntimeError('An older input repair is loaded. Use Undo input layout, then Repair screens and mouse.')
        ok, message = check_layout()
        if not ok: raise RuntimeError(message)
        return 'Input layout correction is already active for this desktop session.'
    marker = record()
    STATE.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='build-',dir=STATE) as directory:
        library = build(directory)
        digest = hashlib.sha256(library.read_bytes()).hexdigest()[:16]
        target = STATE / (digest+'.so')
        # Never overwrite an existing shared object, which could be mapped.
        if not target.exists(): library.replace(target)
    guard()  # recheck after compilation
    baseline = run('xrandr','--query')
    marker.write_text(json.dumps({'library':str(target),'before':baseline},indent=2)+'\n')
    loaded = False
    try:
        result = run('hyprctl','plugin','load',str(target))
        loaded = active()
        if not loaded: raise RuntimeError('Native correction was not loaded: '+result)
        for _ in range(20):
            ok, message = check_layout()
            if ok: return 'Input layout corrected for this desktop session. Reopen Horizon and check all active screens. No autostart change was made.'
            time.sleep(.1)
        raise RuntimeError('Input layout did not converge: '+message)
    except Exception:
        if loaded:
            run('hyprctl','plugin','unload',str(target))
            if active(): raise RuntimeError('Automatic rollback failed; use Undo input layout before reopening Horizon.')
        marker.unlink(missing_ok=True)
        raise

def deactivate():
    runpy.run_path(str(RECOVERY))['require_horizon_closed']()
    if not active(): return 'Input layout correction is not loaded.'
    marker = record()
    target = Path(json.loads(marker.read_text())['library'])
    if target.parent != STATE or target.suffix != '.so': raise RuntimeError('Invalid input-layout rollback path.')
    run('hyprctl','plugin','unload',str(target))
    if active(): raise RuntimeError('Input layout correction is still loaded.')
    marker.unlink(missing_ok=True)
    return 'Input layout correction unloaded; stock XWayland arrangement restored.'

def main():
    action = sys.argv[1] if len(sys.argv)>1 else ''
    if action == 'build' and len(sys.argv)==3: print(build(sys.argv[2])); return
    if action == 'enable': print(activate()); return
    if action == 'disable': print(deactivate()); return
    raise RuntimeError('Usage: control.py build OUTPUT_DIRECTORY | enable | disable')

if __name__ == '__main__':
    try: main()
    except Exception as exc:
        details = getattr(exc,'stderr','') or ''
        print(f'Input layout stopped: {exc}\n{details}',file=sys.stderr)
        sys.exit(1)
