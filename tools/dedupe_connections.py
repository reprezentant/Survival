"""
Quick helper to detect (and optionally remove) duplicate [connection ...] lines inside .tscn files.
Run this from the project root. By default it only reports duplicates (dry-run).
Use --fix to overwrite files after making a .bak backup.

This is safe for duplicate identical connection entries which cause runtime warnings like:
"Signal 'register_hit' is already connected to given callable ..."

Usage:
  python tools\dedupe_connections.py         # dry run, prints summary
  python tools\dedupe_connections.py --fix  # dedupe files in place (creates .bak)

Note: review changes in VCS before committing.
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TSCS = list(ROOT.rglob('*.tscn'))

apply_fix = '--fix' in sys.argv

fixed_files = []
problems = []

for tscn in TSCS:
    text = tscn.read_text(encoding='utf-8')
    lines = text.splitlines()
    conn_lines = []
    conn_indices = {}
    for idx, line in enumerate(lines):
        if line.strip().startswith('[connection '):
            # use the full line as key
            key = line.strip()
            conn_lines.append(key)
            conn_indices.setdefault(key, []).append(idx)

    duplicates = {k: v for k, v in conn_indices.items() if len(v) > 1}
    if duplicates:
        problems.append((tscn, duplicates))
        print(f"Found {len(duplicates)} duplicated connection line(s) in: {tscn}")
        for k, idxs in duplicates.items():
            print(f"  - '{k}' occurs {len(idxs)} times at lines {idxs}")

        if apply_fix:
            # build new lines skipping duplicate occurrences (keep first)
            seen = set()
            new_lines = []
            for line in lines:
                key = line.strip()
                if key.startswith('[connection '):
                    if key in seen:
                        # skip duplicate
                        continue
                    seen.add(key)
                new_lines.append(line)

            bak = tscn.with_suffix(tscn.suffix + '.bak')
            bak.write_text(text, encoding='utf-8')
            tscn.write_text('\n'.join(new_lines) + '\n', encoding='utf-8')
            fixed_files.append(tscn)

if not problems:
    print('No duplicate [connection ...] lines found in any .tscn files.')
else:
    print('\nSummary:')
    print(f'  files_with_duplicates: {len(problems)}')
    if apply_fix:
        print(f'  files_fixed: {len(fixed_files)} (backups with .bak created)')
    else:
        print('  run with --fix to automatically remove duplicate identical connection lines (creates .bak backups).')

print('\nDone.')
