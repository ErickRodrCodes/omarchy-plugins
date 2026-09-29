"""Geometry and input-boundary regressions, without a desktop session."""
import runpy
from pathlib import Path
import unittest

m = runpy.run_path(str(Path(__file__).with_name('input_layout.py')))

def monitor(name, x, y, w=800, h=600, **kw):
    return dict(name=name, x=x, y=y, width=w, height=h, scale=1, **kw)

class LayoutTests(unittest.TestCase):
    def test_arbitrary_count_order_offsets_and_normalization(self):
        arrangements = [
            [monitor('only', 100, -200)],
            [monitor('right', 0, 0), monitor('left', -900, 100)],
            [monitor('bottom', 0, 700), monitor('top', 0, -600)],
            [monitor('a', -900, -700), monitor('b', 0, -700), monitor('c', -900, 0), monitor('d', 0, 0)],
        ]
        for row in arrangements:
            with self.subTest(row=row):
                x,y,w,h = m['geometry'](row)
                randr = '\n'.join(f"{v['name']} connected {v['width']}x{v['height']}+{v['x']-x}+{v['y']-y}" for v in reversed(row))
                self.assertTrue(m['compare'](row, randr)[0])
                self.assertEqual(m['signature'](row),m['signature'](list(reversed(row))))
                for record in m['layout_environment'](row,randr).split(';'):
                    fields=list(map(int,record.split(',')))
                    self.assertEqual(fields[:4],fields[4:])
                for v in row:
                    for px,py in ((0,0),(v['width']-1,v['height']-1)):
                        self.assertTrue(0 <= v['x']-x+px < w)
                        self.assertTrue(0 <= v['y']-y+py < h)

    def test_dell_clipping_layout_is_rejected(self):
        row=[monitor('ASUS',0,0,3840,2160),monitor('Elgato',3840,0,1024,600),monitor('Dell',4864,0,1920,1080)]
        wrong='ASUS connected 3840x2160+0+0\nDell connected 1920x1080+3840+0\nElgato connected 1024x600+5760+0'
        self.assertFalse(m['compare'](row,wrong)[0])
        self.assertIn('3840,0,1920,1080,4864,0,1920,1080',m['layout_environment'](row,wrong))

    def test_disabled_and_incomplete_outputs(self):
        row=[monitor('a',0,0),monitor('off',0,0,disabled=True)]
        self.assertEqual(m['geometry'](row),(0,0,800,600))
        with self.assertRaises(RuntimeError):m['layout_environment'](row,'')
        self.assertFalse(m['compare'](row,'a connected 800x600+0+0\nextra connected 800x600+800+0')[0])

    def test_invalid_layouts(self):
        for row in ([],[monitor('a',0,0),monitor('b',100,100)],
                    [monitor('a',0,0,40000)], [monitor('a',float('nan'),0)],
                    [monitor('a',0.5,0)], [monitor('a',0,0,mirrorOf='b')],
                    [dict(monitor('a',0,0),scale=1.5)], [monitor('a',0,0,transform=1)]):
            with self.subTest(row=row),self.assertRaises(RuntimeError):m['geometry'](row)

    def test_same_outer_bounds_rearrangement_changes_signature(self):
        a=[monitor('a',0,0),monitor('b',800,0)]
        b=[monitor('b',0,0),monitor('a',800,0)]
        self.assertEqual(m['geometry'](a),m['geometry'](b))
        self.assertNotEqual(m['signature'](a),m['signature'](b))

if __name__ == '__main__':unittest.main()
