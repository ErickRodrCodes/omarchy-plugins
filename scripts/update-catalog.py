#!/usr/bin/env python3
"""Refresh catalog metadata from published manifests and render the README table."""
import argparse
import json
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
START = '<!-- plugins:start -->'
END = '<!-- plugins:end -->'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--refresh', action='store_true', help='Fetch published manifests before rendering')
    parser.add_argument('--check', action='store_true', help='Fail if generated files would change')
    args = parser.parse_args()
    path = ROOT / 'plugins.json'
    entries = json.loads(path.read_text())
    for entry in entries:
        if args.refresh and entry.get('repository'):
            url = f"https://raw.githubusercontent.com/{entry['repository']}/main/manifest.json"
            with urlopen(Request(url, headers={'User-Agent': 'omarchy-plugin-catalog'}), timeout=30) as response:
                manifest = json.load(response)
            if manifest['id'] != entry['id']:
                raise ValueError(f"Unexpected plugin identity in {url}")
            entry.update(name=manifest['name'], description=manifest.get('description', ''), version=manifest.get('version'),
                         omarchy=manifest.get('omarchy', {}).get('testedVersion'))
    rows = ['| Plugin | Version | Tested Omarchy | Changelog | Description |', '| --- | --- | --- | --- | --- |']
    def cell(value):
        return str(value).replace('|', '&#124;').replace('\n', ' ')
    for entry in entries:
        if entry.get('repository'):
            url = 'https://github.com/' + entry['repository']
            name = f"[{cell(entry['name'])}]({url})"
            changelog = f'[Changelog]({url}/blob/main/CHANGELOG.md)'
        else:
            name = cell(entry['name']) + ' (unpublished)'
            changelog = f"[Changelog]({entry['changelog']})"
        version = f"`{cell(entry['version'])}`" if entry.get('version') else 'Not versioned'
        omarchy = f"`{cell(entry['omarchy'])}`" if entry.get('omarchy') else 'Not specified'
        rows.append(f'| {name} | {version} | {omarchy} | {changelog} | {cell(entry.get('description', ''))} |')
    readme = ROOT / 'README.md'
    before, rest = readme.read_text().split(START, 1)
    _, after = rest.split(END, 1)
    rendered = before + START + '\n\n' + '\n'.join(rows) + '\n\n' + END + after
    outputs = {path: json.dumps(entries, indent=2) + '\n', readme: rendered}
    changed = [p for p, text in outputs.items() if p.read_text() != text]
    if args.check:
        if changed:
            raise SystemExit('Catalog is stale: ' + ', '.join(p.name for p in changed))
    else:
        for p in changed:
            p.write_text(outputs[p])
    print('Catalog is current.' if not changed else 'Catalog updated.')


if __name__ == '__main__':
    main()
