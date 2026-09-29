#!/usr/bin/env bash
set -euo pipefail
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
timeout 1 qs -c hshell ipc call hshell close >/dev/null 2>&1 || true
sleep 0.15
python3 - "$scripts" "${1:-eng}" <<'PY'
import importlib.util
from pathlib import Path
import subprocess
import sys
base=Path(sys.argv[1]);spec=importlib.util.spec_from_file_location('ocr',base/'utility-tools.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
try:
    data=module.main('ocr-region',sys.argv[2])
    message='Text Copied' if data.get('text','').strip() else ''
except Exception as error:
    print(str(error),file=sys.stderr);message='Image to Text Failed'
if message:subprocess.run([sys.executable,str(base/'shell-notice.py'),'ocr',message])
PY
