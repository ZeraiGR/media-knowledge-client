#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path
import re
import sys

tag, directory = sys.argv[1:]
if not re.fullmatch(r'v\d+\.\d+\.\d+', tag):
    raise ValueError('stable version tag required')
root = Path(directory)
names = {'android':'MediaKnowledge-android.apk', 'macos':'MediaKnowledge-macos.dmg', 'windows':'MediaKnowledge-windows-x64-setup.exe'}
packages = {}
checksums = []
for platform, name in names.items():
    data = (root / name).read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    packages[platform] = {'url':f'https://github.com/ZeraiGR/media-knowledge-client/releases/download/{tag}/{name}', 'sha256':digest, 'size':len(data)}
    checksums.append(f'{digest}  {name}\n')
(root / 'update-manifest.json').write_text(json.dumps({'schemaVersion':1,'version':tag[1:],'packages':packages}, indent=2)+'\n')
(root / 'SHA256SUMS').write_text(''.join(checksums))
