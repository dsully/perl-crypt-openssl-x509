#!/usr/bin/env bash
# Runs podchecker after edits to X509.pm to catch broken POD before it reaches the build
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | python3 -c "
import sys, json
d = json.load(sys.stdin)
fp = d.get('file_path') or d.get('tool_input', {}).get('file_path', '')
print(fp)
" 2>/dev/null || echo "")

if [[ "$file_path" == *"X509.pm" ]]; then
    echo "--- POD syntax check ---"
    if command -v podchecker &>/dev/null; then
        podchecker "$file_path" && echo "POD OK"
    else
        perl -MPod::Checker -e "
my \$checker = Pod::Checker->new;
\$checker->parse_from_file('$file_path');
my \$errors = \$checker->num_errors;
exit(\$errors > 0 ? 1 : 0);
" && echo "POD OK"
    fi
fi
