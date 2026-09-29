"""Use the same layout model as the launch wrapper."""
from pathlib import Path
import runpy
_model = runpy.run_path(str(Path(__file__).parent / 'plugin/scripts/layout_model.py'))
geometry = _model['geometry']
compare = _model['compare']
layout_environment = _model['layout_environment']
signature = _model['signature']
