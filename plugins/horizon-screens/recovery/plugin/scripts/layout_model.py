"""One coordinate model for active Hyprland outputs, X11, and Horizon."""
import math
import re


def geometry(monitors):
    active = [m for m in monitors if not m.get('disabled', False)]
    if not active:
        raise RuntimeError('No active displays.')
    for m in active:
        if m.get('scale', 1) != 1 or m.get('transform', 0) != 0 or m.get('mirrorOf', 'none') not in ('none', None):
            raise RuntimeError('Display repair currently requires scale 1, no rotation, and no mirroring.')
        for key in ('x', 'y', 'width', 'height'):
            v = m[key]
            if not isinstance(v, (int, float)) or not math.isfinite(v) or int(v) != v:
                raise RuntimeError('Display coordinates must be finite integers.')
        if m['width'] <= 0 or m['height'] <= 0:
            raise RuntimeError('Display dimensions must be positive.')
    for index, a in enumerate(active):
        for b in active[index+1:]:
            if (a['x'] < b['x']+b['width'] and b['x'] < a['x']+a['width'] and
                    a['y'] < b['y']+b['height'] and b['y'] < a['y']+a['height']):
                raise RuntimeError('Overlapping display rectangles are not supported.')
    x, y = min(m['x'] for m in active), min(m['y'] for m in active)
    width = max(m['x']+m['width'] for m in active)-x
    height = max(m['y']+m['height'] for m in active)-y
    if width > 32767 or height > 32767:
        raise RuntimeError('Combined display bounds exceed X11 limits.')
    return x, y, width, height


def compare(monitors, randr):
    try:
        x, y, _, _ = geometry(monitors)
    except RuntimeError as exc:
        return False, str(exc)
    actual = {}
    for line in randr.splitlines():
        match = re.match(r'^(\S+) connected(?: primary)? (\d+)x(\d+)([+-]\d+)([+-]\d+)(?:\s|$)', line)
        if match:
            name, width, height, px, py = match.groups()
            actual[name] = tuple(map(int, (px, py, width, height)))
    expected = {m['name']: (m['x']-x, m['y']-y, m['width'], m['height']) for m in monitors if not m.get('disabled', False)}
    if set(expected) != set(actual):
        return False, 'Cannot match all active displays between Hyprland and XWayland.'
    differences = [f'{name}: XWayland {actual[name]}, expected {value}' for name, value in expected.items() if actual[name] != value]
    if differences:
        return False, 'Input layout differs. Quit Horizon and use Repair screens and mouse.\n' + '\n'.join(differences)
    return True, 'Display rectangles and pointer boundaries agree with Hyprland (normalized X11 origin).'


def layout_environment(monitors, randr):
    x, y, _, _ = geometry(monitors)
    expected = {m['name']: (m['x']-x, m['y']-y, m['width'], m['height']) for m in monitors if not m.get('disabled', False)}
    actual = {}
    for line in randr.splitlines():
        match = re.match(r'^(\S+) connected(?: primary)? (\d+)x(\d+)([+-]\d+)([+-]\d+)(?:\s|$)', line)
        if match:
            name, w, h, px, py = match.groups()
            actual[name] = tuple(map(int, (px, py, w, h)))
    if set(actual) != set(expected):
        raise RuntimeError('Cannot match every active Hyprland output to XWayland; no partial layout will be used.')
    return ';'.join(','.join(map(str, actual[name]+expected[name])) for name in actual)


def signature(monitors):
    import json
    geometry(monitors)
    return json.dumps(sorted((m['name'], m['x'], m['y'], m['width'], m['height'])
                             for m in monitors if not m.get('disabled', False)), separators=(',', ':'))


if __name__ == '__main__':
    import json
    import subprocess
    import sys
    try:
        monitors = json.loads(subprocess.check_output(['hyprctl', '-j', 'monitors'], text=True))
        randr = subprocess.check_output(['xrandr', '--query'], text=True)
        print(signature(monitors) if '--signature' in sys.argv else layout_environment(monitors, randr))
    except (RuntimeError, OSError, subprocess.CalledProcessError) as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
