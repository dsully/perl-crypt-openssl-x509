#!/usr/bin/env bash
# Blocks direct edits to Makefile.PL — modify dist.ini or maint/Makefile.PL.include instead
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | python3 -c "
import sys, json
d = json.load(sys.stdin)
# Handle both PreToolUse formats (direct or nested under tool_input)
fp = d.get('file_path') or d.get('tool_input', {}).get('file_path', '')
print(fp)
" 2>/dev/null || echo "")

if [[ "$file_path" == *"Makefile.PL" ]]; then
    echo "ERROR: Do not edit Makefile.PL directly." >&2
    echo "  - To change build logic: edit maint/Makefile.PL.include" >&2
    echo "  - To change dist metadata: edit dist.ini and run dzil build" >&2
    exit 2
fi
